module RailsSemanticLogger
  module Sequel
    class LogSubscriber < ActiveSupport::LogSubscriber
      class << self
        attr_reader :logger
      end

      def self.runtime= value
        # ::ActiveRecord::RuntimeRegistry.sql_runtime = value
        RequestStore.store[:sql_runtime] = value
      end

      def self.runtime
        # ::ActiveRecord::RuntimeRegistry.sql_runtime ||= 0
        RequestStore.fetch(:sql_runtime) { 0 }
      end

      def self.count= value
        RequestStore.store[:sql_count] = value
      end

      def self.count
        RequestStore.fetch(:sql_count) { 0 }
      end

      def self.reset_runtime
        previous = runtime
        self.runtime = 0
        previous
      end

      def self.reset_count
        previous = count
        self.count = 0
        previous
      end

      def sql event
        self.class.runtime += event.duration
        self.class.count += 1
        return unless logger.debug?

        payload = event.payload
        name = payload[:name]

        log_payload = {sql: payload[:sql].squeeze(" ")}
        log_payload[:binds] = bind_values payload unless (payload[:binds] || []).empty?
        log_payload[:allocations] = event.allocations if event.respond_to? :allocations
        log_payload[:cached] = event.payload[:cached]

        log = {message: name, payload: log_payload, duration: event.duration}

        # Log the location of the query itself.
        if logger.send(:level_index) >= SemanticLogger.backtrace_level_index
          log[:backtrace] = SemanticLogger::Utils.strip_backtrace caller
        end

        logger.debug log
      end

      private

      @logger = SemanticLogger["Sequel"]

      # When multiple values are received for a single bound field, it is converted into an array
      def add_bind_value binds, key, value
        key = key.downcase.to_sym unless key.nil?
        value = (Array(binds[key]) << value) if binds.key? key
        binds[key] = value
      end

      def logger
        self.class.logger
      end

      def bind_values payload
        binds = {}
        binds = "  " + payload[:binds].map { |col, v| [col.name, v] }
                                      .inspect
        payload[:binds].each { |col, value| add_bind_value binds, col.name, value }
        binds
      end
    end
  end
end

RailsSemanticLogger::Sequel::LogSubscriber.attach_to :sequel
