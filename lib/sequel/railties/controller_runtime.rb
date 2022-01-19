# frozen_string_literal: true

require "active_support/core_ext/module/attr_internal"
require "rails_semantic_logger/sequel/log_subscriber"

module Sequel
  module Railties
    module ControllerRuntime
      extend ActiveSupport::Concern

      module ClassMethods
        def log_process_action payload
          messages = super
          db_runtime = payload[:db_runtime]
          db_query_count = payload[:db_query_count]
          if db_runtime && db_query_count
            messages << (format "Sequel: %.1fms & %d queries", db_runtime.to_f, db_query_count)
          end
          messages
        end
      end

      private

      attr_internal :db_runtime, :db_query_count

      def process_action action, *args
        # We also need to reset the runtime before each action
        # because of queries in middleware or in cases we are streaming
        # and it won't be cleaned up by the method below.
        RailsSemanticLogger::Sequel::LogSubscriber.reset_runtime
        RailsSemanticLogger::Sequel::LogSubscriber.reset_count
        super
      end

      def cleanup_view_runtime
        if logger && logger.info?
          db_rt_before_render = RailsSemanticLogger::Sequel::LogSubscriber.reset_runtime
          self.db_runtime = (db_runtime || 0) + db_rt_before_render
          runtime = super
          db_rt_after_render = RailsSemanticLogger::Sequel::LogSubscriber.reset_runtime
          self.db_runtime += db_rt_after_render
          runtime - db_rt_after_render
        else
          super
        end
      end

      def append_info_to_payload payload
        super
        payload[:db_runtime] =
          (db_runtime || 0) + RailsSemanticLogger::Sequel::LogSubscriber.reset_runtime
        payload[:db_query_count] =
          (db_query_count || 0) + RailsSemanticLogger::Sequel::LogSubscriber.reset_count
      end
    end
  end
end

ActionController::Base.include Sequel::Railties::ControllerRuntime
ActionController::API.include Sequel::Railties::ControllerRuntime
