class MapWithIndifferentAccess
  module KeyCoercion

    class DeepCoercer
      include MapWithIndifferentAccess::WithConveniences

      attr_reader :strategy

      def initialize(strategy)
        @strategy = strategy
      end

      def call(obj)
        if ::Hash === obj
          coerce_hash( obj )
        elsif MWIA === obj
          coerce_mwia( obj )
        elsif ::Array === obj
          coerce_array( obj )
        elsif MWIA::Array === obj
          coerce_mwia_array( obj )
        elsif obj.respond_to?(:to_hash) && obj.respond_to?(:each_pair)
          coerce_hash( obj.to_hash )
        elsif obj.respond_to?(:to_ary)
          coerce_array( obj.to_ary )
        else
          obj
        end
      end

      private

      def coerce_hash(obj)
        result = {}
        obj.each_pair{ |(k,v)|
          k = strategy.coerce( k ) if strategy.needs_coercion?( k )
          result[ k ] = call( v )
        }
        result
      end

      def coerce_mwia(obj)
        result_hash = coerce_hash( obj )
        MWIA.new( result_hash )
      end

      def coerce_array( obj )
        result = obj.dup
        result.map!{ |item| call(item) }
        result
      end

      def coerce_mwia_array(obj)
        result_array = coerce_array( obj.inner_array )
        MWIA::Array.new( result_array )
      end
    end

  end
end
