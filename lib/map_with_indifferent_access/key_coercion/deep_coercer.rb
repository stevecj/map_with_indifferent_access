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
        does_need_key_coercion = obj.each_key.any?{ |key|
          strategy.needs_coercion?( key )
        }
        result = does_need_key_coercion ? {} : obj

        obj.each_pair do |(key,value)|
          key = strategy.coerce( key ) if strategy.needs_coercion?( key )
          new_value = recursively_coerce( value )
          if result.equal?( obj )
            unless new_value.equal?( value )
              result = obj.dup
              result[ key ] = new_value
            end
          else
            result[ key ] = new_value
          end
        end
        result
      end

      def coerce_array( obj )
        result = obj
        obj.each_with_index do |item,i|
          new_item = recursively_coerce(item)
          unless new_item.equal?( item )
            result = obj.dup if result.equal?( obj )
            result[ i ] = new_item
          end
        end
        result
      end
    end

  end
end
