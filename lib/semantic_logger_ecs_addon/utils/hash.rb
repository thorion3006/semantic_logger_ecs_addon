# frozen_string_literal: true

module SemanticLoggerEcsAddon
  module Utils
    class Hash < ::Hash
      # With thanks to https://github.com/rails/rails/blob/83217025a171593547d1268651b446d3533e2019/activesupport/lib/active_support/core_ext/hash/slice.rb#L24
      # Removes and returns the key/value pairs matching the given keys.
      #
      #   hash = { a: 1, b: 2, c: 3, d: 4 }
      #   hash.extract!(:a, :b) # => {:a=>1, :b=>2}
      #   hash                  # => {:c=>3, :d=>4}
      def extract! *keys
        keys.each_with_object self.class.new do |key, result|
          result[key] = delete key if key? key
        end
      end
    end
  end
end
