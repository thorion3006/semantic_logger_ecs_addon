# frozen_string_literal: true

require "pathname"
require "zeitwerk"
if defined? ActiveSupport::LogSubscriber
  require_relative "rails_semantic_logger/sequel/log_subscriber"
end
if defined?(ActiveSupport::Notifications)
  require_relative "sequel/database/active_support_notification"
end
require_relative "sequel/railties/controller_runtime" if defined?(ActionController)

loader = Zeitwerk::Loader.for_gem
loader.setup

# Main namespace.
module SemanticLoggerEcsAddon
  RootPath = Pathname.getwd
  BacktraceCleaner = Utils::BacktraceCleaner.new
  BacktraceCleaner.add_filter { |line| line.gsub(RootPath.to_s, "") }
  BacktraceCleaner.add_silencer { |line| %r(puma|ruby/gems|rubygems).match?(line) }
end
