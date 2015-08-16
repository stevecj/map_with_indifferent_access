require "map_with_indifferent_access/key_coercion/deep_coercer"

class MapWithIndifferentAccess
  module KeyCoercion
    include MapWithIndifferentAccess::WithConveniences

    extend self

    def deeply_symbolize(obj)
      deep_symbolizer.call( obj )
    end

    def deeply_stringify(obj)
      deep_stringifier.call( obj )
    end

    private

    def deep_symbolizer
      @deep_symbolizer ||= DeepCoercer.new( SymbolizationStrategy )
    end

    module SymbolizationStrategy
      def self.needs_coercion?(key)
        !( Symbol === key )
      end

      def self.coerce(key)
        key.to_s.to_sym
      end
    end

    def deep_stringifier
      @deep_stringifier ||= DeepCoercer.new( StringificationStrategy )
    end

    module StringificationStrategy
      def self.needs_coercion?(key)
        !( String === key )
      end

      def self.coerce(key)
        key.to_s
      end
    end

  end
end
