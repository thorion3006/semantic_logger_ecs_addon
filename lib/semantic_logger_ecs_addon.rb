# frozen_string_literal: true

require "pathname"
require "semantic_logger_ecs_addon/utils/backtrace_cleaner"
require "semantic_logger_ecs_addon/utils/hash"
require "semantic_logger_ecs_addon/formatters/base"
require "semantic_logger_ecs_addon/formatters/json"
require "semantic_logger_ecs_addon/formatters/raw"

# Main namespace.
module SemanticLoggerEcsAddon
  RootPath = Pathname.getwd
  BacktraceCleaner = Utils::BacktraceCleaner.new
  BacktraceCleaner.add_filter { |line| line.gsub(RootPath.to_s, "") }
  BacktraceCleaner.add_silencer { |line| %r(puma|ruby/gems|rubygems).match?(line) }
end
