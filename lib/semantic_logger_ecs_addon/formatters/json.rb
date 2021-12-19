# frozen_string_literal: true

require "oj"

module SemanticLoggerEcsAddon
  module Formatters
    class Json < Raw
      # Default JSON time format is ISO8601
      def initialize time_format: :iso_8601, precision: 3, **args
        super(time_format: time_format, precision: precision, **args)
      end

      # Returns log messages in JSON format
      def call log, logger
        Oj.dump(super(log, logger), nilnil: true, escape_mode: :json, mode: :rails)
      rescue SystemStackError => _error
        Oj.dump(super(log, logger).transform_keys {|key| key.to_s }, nilnil: true, escape_mode: :json, mode: :object)
      end
    end
  end
end
