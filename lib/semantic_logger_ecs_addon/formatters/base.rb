# frozen_string_literal: true

require "semantic_logger/formatters/base"

module SemanticLoggerEcsAddon
  module Formatters
    class Base < SemanticLogger::Formatters::Base
      # Fields are added by populating this hash.
      attr_accessor :hash, :time_key, :log_labels, :formatted_payload

      # Parameters
      #   time_format: [String|Symbol|nil]
      #     See Time#strftime for the format of this string.
      #     :iso_8601 Outputs an ISO8601 Formatted timestamp.
      #     :ms       Output in miliseconds since epoch.
      #     nil:      Returns Empty string for time ( no time is output ).
      #     Default: '%Y-%m-%d %H:%M:%S.%<precision>N'
      #   log_host: [Boolean]
      #     Whether or not to include hostname in logs
      #     Default: true
      #   precision: [Integer]
      #     How many fractional digits to log times with.
      #     Default: PRECISION (6, except on older JRuby, where 3)
      def initialize time_key: :time, **args
        @time_key = time_key
        @log_application = true
        super(**args)
      end

      # Host name
      def host
        log_labels[:host] = logger.host if log_host && logger.host
      end

      # Application name
      def application
        log_labels[:application] = logger.application if logger && logger.application
      end

      # Environment
      def environment
        if log_environment && logger && logger.environment
          log_labels[:environment] = logger.environment
        end
      end

      # Named Tags
      def named_tags
        log_labels[:named_tags] = log.named_tags if log.named_tags && !log.named_tags.empty?
      end

      # Date & time
      def time
        hash[time_key] = format_time log.time.utc
      end

      def labels
        self.log_labels ||= {}
        host
        application
        environment
        named_tags
        hash[:labels] = log_labels unless log_labels.empty?
      end

      # Log message
      def message
        hash[:message] = "#{log.name} -- #{log.cleansed_message}" if log.message
        hash[:message] = "#{log.metric} -- #{log.metric_amount}" if log.metric && log.metric_amount
      end

      # Tags
      def tags
        hash[:tags] = log.tags if log.tags && !log.tags.empty?
      end

      # Exception
      def exception
        return log.exception if log.exception

        unless log.payload.respond_to?(:empty?) && log.payload[:exception].class.ancestors.include?(StandardError)
          return
        end

        log.payload[:exception]
      end

      def inner_exception exception
        if exception.respond_to?(:cause) && exception.cause
          exception.cause
        elsif exception.respond_to?(:continued_exception) && exception.continued_exception
          exception.continued_exception
        elsif exception.respond_to?(:original_exception) && exception.original_exception
          exception.original_exception
        end
      end

      # Call the block for exception and any nested exception
      def each_exception exception
        # With thanks to https://github.com/bugsnag/bugsnag-ruby/blob/6348306e44323eee347896843d16c690cd7c4362/lib/bugsnag/notification.rb#L81
        depth      = 0
        exceptions = []
        e = exception
        while !e.nil? && !exceptions.include?(e) && exceptions.length < 5
          exceptions << e
          yield e, depth

          depth += 1
          e = inner_exception e
        end
      end

      def exception_hash exception
        {
          "error.type": exception.class.name,
          "error.message": exception.message,
          "error.stack_trace": BacktraceCleaner.clean(exception.backtrace)
        }
      end

      def error_log?
        !hash[:"error.type"].nil?
      end

      def initialize_rack_keys
        formatted_payload[:request] ||= {}
        formatted_payload[:response] ||= {}
        formatted_payload[:metrics] ||= {}
      end

      def rack_request
        formatted_payload[:request].merge! formatted_payload.extract!(
          :controller,
          :action,
          :params,
          :method,
          :path,
          :request_id
        )
        formatted_payload[:request][:body] = formatted_payload[:request].delete :params
      end

      def rack_response
        formatted_payload[:response].merge! formatted_payload.extract!(:status, :status_message)
      end

      def rack_metrics
        metrics_keys = formatted_payload.keys.select { |k| k.to_s.end_with?("_runtime") }
        formatted_payload[:metrics].merge! formatted_payload.extract!(:allocations, *metrics_keys)
        formatted_payload[:metrics][:object_allocations] =
          formatted_payload[:metrics].delete :allocations
      end

      def rack_extract
        return unless formatted_payload.key? :controller

        initialize_rack_keys
        rack_request
        rack_response
        rack_metrics
        formatted_payload.delete :format
      end

      def format_payload
        if log.payload.respond_to?(:empty?) && !log.payload.empty?
          self.formatted_payload = Utils::Hash[**log.payload]

          rack_extract
        else
          self.formatted_payload = {}
        end
      end

      def request
        hash[:"http.request.id"] = formatted_payload.dig :request, :request_id
        hash[:"http.request.body.content"] = formatted_payload.dig :request, :body
        hash[:"http.request.method"] = formatted_payload.dig :request, :method
      end

      def response
        hash[:"http.response.body.content"] = formatted_payload.dig :response, :body
        hash[:"http.response.status_code"] = formatted_payload.dig :response, :status
      end

      # Ruby file name and line number that logged the message.
      def file_name_and_line
        file, line = log.file_name_and_line
        return unless file

        hash[:"log.origin.file.name"] = file
        hash[:"log.origin.file.line"] = line.to_i
      end

      def calculated_log_level
        return log.level if log.level_index > 2

        (formatted_payload.dig(:response, :status) || 0) >= 500 ? "error" : log.level
      end

      # ElasticAPM
      def apm_agent_present_and_running?
        return false unless defined?(::ElasticAPM)

        ElasticAPM.running?
      end
    end
  end
end
