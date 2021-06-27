# frozen_string_literal: true

require "json"

module SemanticLoggerEcsAddon
  module Formatters
    class Json < Raw
      # Default JSON time format is ISO8601
      def initialize time_format: :iso_8601, precision: 3, **args
        super(time_format: time_format, precision: precision, **args)
      end

      # Returns log messages in JSON format
      def call log, logger
        super(log, logger).to_json
      end
    end
  end
end
