# frozen_string_literal: true

module SemanticLoggerEcsAddon
  # Gem identity information.
  module Identity
    NAME = "semantic_logger_ecs_addon"
    LABEL = "Semantic Logger Ecs Addon"
    VERSION = "0.1.1"
    VERSION_LABEL = "#{LABEL} #{VERSION}"
    SUMMARY = "A semantic logger formatter that formats the logs according to Elastic Common Schema and adds APM trace data if ElasticAPM is enabled."
  end
end
