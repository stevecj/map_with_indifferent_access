require "map_with_indifferent_access/normalization/deep_normalizer"

class MapWithIndifferentAccess
  module Normalization
    include MapWithIndifferentAccess::WithConveniences

    extend self

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

    def deep_key_symbolizer
      @deep_key_symbolizer ||= DeepNormalizer.new( KeySymbolizationStrategy )
    end

    module KeyStrategy
      def self.needs_coercion?(key)
        raise NotImplementedError, "Including-module responsibility"
      end

      def self.coerce(key)
        raise NotImplementedError, "Including-module responsibility"
      end
    end

    module KeySymbolizationStrategy
      extend Normalization::KeyStrategy

      def self.needs_coercion?(key)
        !( Symbol === key )
      end

      def self.coerce(key)
        key.to_s.to_sym
      end
    end

    def deep_key_stringifier
      @deep_key_stringifier ||= DeepNormalizer.new( KeyStringificationStrategy )
    end

    module KeyStringificationStrategy
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
