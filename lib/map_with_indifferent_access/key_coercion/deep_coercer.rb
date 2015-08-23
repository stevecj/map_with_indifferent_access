class MapWithIndifferentAccess
  module KeyCoercion

    class DeepCoercer
      include MapWithIndifferentAccess::WithConveniences

      attr_reader :strategy

      def initialize(strategy)
        @strategy = strategy
      end

      def call(obj)
        if MWIA::WrapsCollection === obj
          coerced_inner_col = recursively_coerce( obj )
          MWIA::Values.externalize( coerced_inner_col )
        else
          recursively_coerce( obj )
        end
      end

      private

      def recursively_coerce(obj)
        if ::Hash === obj
          coerce_hash( obj )
        elsif MWIA === obj
          coerce_hash( obj.inner_map )
        elsif ::Array === obj
          coerce_array( obj )
        elsif MWIA::Array === obj
          coerce_array( obj.inner_array )
        elsif obj.respond_to?(:to_hash) && obj.respond_to?(:each_pair)
          coerce_hash( obj.to_hash )
        elsif obj.respond_to?(:to_ary)
          coerce_array( obj.to_ary )
        else
          obj
        end
      end

      def coerce_hash(obj)
        result = {}
        obj.each_pair{ |(k,v)|
          k = strategy.coerce( k ) if strategy.needs_coercion?( k )
          result[ k ] = recursively_coerce( v )
        }
        result
      end

      def coerce_array( obj )
        result = obj.dup
        result.map!{ |item| recursively_coerce(item) }
        result
      end
    end

  end
end
