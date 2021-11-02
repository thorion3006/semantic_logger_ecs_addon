require "rails_semantic_logger/sequel/log_subscriber" if defined? ActiveSupport::LogSubscriber
require "sequel/database" if defined?(ActiveSupport::Notifications)
require "sequel/railties/controller_runtime" if defined?(ActionController)
