class MapWithIndifferentAccess

  class Array
    attr_reader :inner_array

    def initialize(inner_array = [])
      @inner_array = inner_array
    end

    def []=(index, value)
      inner_array[index] = value
    end

    def [](index)
      item = inner_array[index]
      unless MapWithIndifferentAccess === item || self.class === item
        if item.respond_to?( :to_hash )
          item = MapWithIndifferentAccess.new( item )
        elsif item.respond_to?( :to_ary )
          item = self.class.new( item )
        end
      end
      item
    end
  end

end
