# frozen_string_literal: true

module SemanticLoggerEcsAddon
  module Formatters
    class Raw < Base
      def initialize time_format: :none, time_key: :@timestamp, **args
        @time_key = time_key
        super(time_format: time_format, time_key: @time_key, **args)
      end

      def base
        time
        labels
        message
        tags
      end

      def ecs
        hash[:"ecs.version"] = "1.10"
      end

      def error
        root = hash
        each_exception exception do |e, i|
          if i.zero?
            root.merge! exception_hash e
          else
            root[:"error.cause"] = exception_hash e
            root = root[:"error.cause"]
          end
        end
      end

      def event
        hash[:"event.dataset"] = "#{logger.application}.log"
        hash[:"event.duration"] = (log.duration || 0) * 1000000
        hash[:"event.outcome"] = error_log? ? "failure" : "success"
      end

      def http
        request
        response
      end

      def ecs_log
        hash[:"log.level"] = calculated_log_level
        hash[:"log.logger"] = log.name
        file_name_and_line
      end

      def ecs_process
        hash[:"process.thread.name"] = log.thread_name
        hash[:"process.pid"] = pid
      end

      def ecs_service
        hash[:"service.name"] = logger.application
      end

      def ecs_source
        hash[:"source.ip"] = formatted_payload.delete :remote_ip
      end

      def ecs_tracing
        return unless apm_agent_present_and_running?

        hash[:"transaction.id"] = ElasticAPM.current_transaction&.id
        hash[:"trace.id"] = ElasticAPM.current_transaction&.trace_id
        hash[:"span.id"] = ElasticAPM.current_span&.id
      end

      def ecs_url
        hash[:"url.path"] = formatted_payload.dig :request, :path
      end

      def ecs_user
        hash[:"user.email"] = formatted_payload.dig :user, :email
        hash[:"user.full_name"] = formatted_payload.dig :user, :full_name
        hash[:"user.id"] = formatted_payload.dig :user, :id
        hash[:"user.name"] = formatted_payload.dig :user, :name
        hash[:"user.domain"] = formatted_payload.dig :user, :type
      end

      def extras
        return unless formatted_payload.respond_to?(:empty?) && !formatted_payload.empty? && formatted_payload.respond_to?(:has_key?)

        hash.merge! formatted_payload.except(:request, :response, :user)
      end

      # Returns log messages in Hash format
      def call log, logger
        self.hash   = {}
        self.log    = log
        self.logger = logger
        format_payload

        base
        ecs
        error
        event
        http
        ecs_log
        ecs_process
        ecs_service
        ecs_source
        ecs_tracing
        ecs_url
        ecs_user
        extras

        hash.compact
      end
    end
  end
end
