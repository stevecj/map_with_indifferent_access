require "map_with_indifferent_access/normalization/deep_normalizer"

module MapWithIndifferentAccess
  module Normalization
    extend self

    # Deeply normalizes [Hash]-like and [Array]-like hash entry
    # values and array items, preserving all of the existing key
    # values from the inner collections ([String], [Symbol], or
    # otherwise).  See
    # [MapWithIndifferentAccess::Normalization::DeepNormalizer#call]
    # for more details.
    def deeply_normalize(obj)
      deep_basic_normalizer.call( obj )
    end

    # Deeply coerces keys to [Symbol] type. See
    # [MapWithIndifferentAccess::Normalization::DeepNormalizer#call]
    # for more details.
    def deeply_symbolize_keys(obj)
      deep_key_symbolizer.call( obj )
    end

    # Deeply coerces keys to [String] type. See
    # [MapWithIndifferentAccess::Normalization::DeepNormalizer#call]
    # for more details.
    def deeply_stringify_keys(obj)
      deep_key_stringifier.call( obj )
    end

    private

    module KeyStrategy
      def self.needs_coercion?(key)
        raise NotImplementedError, "Including-module responsibility"
      end

      def self.coerce(key)
        raise NotImplementedError, "Including-module responsibility"
      end
    end

    def deep_basic_normalizer
      @deep_basic_normalizer ||= DeepNormalizer.new( NullKeyStrategy )
    end

    module NullKeyStrategy
      extend Normalization::KeyStrategy

      def self.needs_coercion?(key)
        false
      end

      def self.coerce(key)
        key
      end
    end

    def deep_key_symbolizer
      @deep_key_symbolizer ||= DeepNormalizer.new( SymbolizationKeyStrategy )
    end

    module SymbolizationKeyStrategy
      extend Normalization::KeyStrategy

      def self.needs_coercion?(key)
        !( Symbol === key )
      end

      def self.coerce(key)
        key.to_s.to_sym
      end
    end

    def deep_key_stringifier
      @deep_key_stringifier ||= DeepNormalizer.new( StringificationKeyStrategy )
    end

    module StringificationKeyStrategy
      extend Normalization::KeyStrategy

      def self.needs_coercion?(key)
        !( String === key )
      end

      def self.coerce(key)
        key.to_s
      end
    end

  end
end
