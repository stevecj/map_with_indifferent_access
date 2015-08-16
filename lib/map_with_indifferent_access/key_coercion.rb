class MapWithIndifferentAccess
  module KeyCoercion
    include MapWithIndifferentAccess::WithConveniences

    extend self

    def deeply_symbolize(obj)
      if ::Hash === obj
        deeply_symbolize_hash( obj )
      elsif MWIA === obj
        deeply_symbolize_mwia( obj )
      elsif ::Array === obj
        deeply_symbolize_array( obj )
      elsif MWIA::Array === obj
        deeply_symbolize_mwia_array( obj )
      elsif obj.respond_to?(:to_hash) && obj.respond_to?(:each_pair)
        deeply_symbolize_hash( obj.to_hash )
      elsif obj.respond_to?(:to_ary)
        deeply_symbolize_array( obj.to_ary )
      else
        obj
      end
    end

    def deeply_symbolize_hash(obj)
      result = {}
      obj.each_pair{ |(k,v)|
        k = k.to_s.to_sym unless Symbol == k
        result[ k ] = deeply_symbolize( v )
      }
      result
    end

    def deeply_symbolize_mwia(obj)
      result_hash = deeply_symbolize_hash( obj )
      MWIA.new( result_hash )
    end

    def deeply_symbolize_array( obj )
      result = obj.dup
      result.map!{ |item| deeply_symbolize(item) }
      result
    end

    def deeply_symbolize_mwia_array(obj)
      result_array = deeply_symbolize_array( obj.inner_array )
      MWIA::Array.new( result_array )
    end
  end
end
