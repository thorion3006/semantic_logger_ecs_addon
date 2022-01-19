# frozen_string_literal: true

require_relative "lib/semantic_logger_ecs_addon/identity"

Gem::Specification.new do |spec|
  spec.name = SemanticLoggerEcsAddon::Identity::NAME
  spec.version = SemanticLoggerEcsAddon::Identity::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Sajeev Ramasamy"]
  spec.email = ["thorion3006@gmail.com"]
  spec.homepage = "https://github.com/thorion3006/semantic_logger_ecs_addon"
  spec.summary = SemanticLoggerEcsAddon::Identity::SUMMARY
  spec.license = "MIT"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/thorion3006/semantic_logger_ecs_addon/issues",
    "changelog_uri" => "https://github.com/thorion3006/semantic_logger_ecs_addon/blob/master/CHANGES.md",
    "documentation_uri" => "https://github.com/thorion3006/semantic_logger_ecs_addon",
    "source_code_uri" => "https://github.com/thorion3006/semantic_logger_ecs_addon",
    "rubygems_mfa_required" => "true"
  }

  spec.signing_key = Gem.default_key_path
  spec.cert_chain = [Gem.default_cert_path]

  spec.required_ruby_version = ">= 2.7", "< 4"

  spec.add_runtime_dependency "oj", "~> 3.13"
  spec.add_runtime_dependency "request_store_rails", "~> 2.0"
  spec.add_runtime_dependency "semantic_logger", "~> 4.4"

  spec.files = Dir["lib/**/*"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.require_paths = ["lib"]
end
