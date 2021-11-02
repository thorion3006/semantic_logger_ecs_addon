# frozen_string_literal: true

require "pathname"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore "rails_semantic_logger"
loader.ignore "sequel"
loader.ignore "semantic_logger_ecs_addon/sequel.rb"
loader.setup

# Main namespace.
module SemanticLoggerEcsAddon
  RootPath = Pathname.getwd
  BacktraceCleaner = Utils::BacktraceCleaner.new
  BacktraceCleaner.add_filter { |line| line.gsub(RootPath.to_s, "") }
  BacktraceCleaner.add_silencer { |line| %r(puma|ruby/gems|rubygems).match?(line) }
end
