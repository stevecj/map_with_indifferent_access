require "map_with_indifferent_access/key_coercion/deep_coercer"

class MapWithIndifferentAccess
  module KeyCoercion
    include MapWithIndifferentAccess::WithConveniences

    extend self

    # Deeply coerces keys to [Symbol] type. See
    # [MapWithIndifferentAccess::KeyCoercion::DeepCoercer#call]
    # for more details.
    def deeply_symbolize(obj)
      deep_symbolizer.call( obj )
    end

    # Deeply coerces keys to [String] type. See
    # [MapWithIndifferentAccess::KeyCoercion::DeepCoercer#call]
    # for more details.
    def deeply_stringify(obj)
      deep_stringifier.call( obj )
    end

    private

    def deep_symbolizer
      @deep_symbolizer ||= DeepCoercer.new( SymbolizationStrategy )
    end

    module Strategy
      def self.needs_coercion?(key)
        raise NotImplementedError, "Including-module responsibility"
      end

      def self.coerce(key)
        raise NotImplementedError, "Including-module responsibility"
      end
    end

    module SymbolizationStrategy
      extend KeyCoercion::Strategy

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
      extend KeyCoercion::Strategy

      def self.needs_coercion?(key)
        !( String === key )
      end

      def self.coerce(key)
        key.to_s
      end
    end

  end
end
