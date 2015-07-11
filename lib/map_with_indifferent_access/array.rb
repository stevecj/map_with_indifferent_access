class MapWithIndifferentAccess

  class Array

    def self.try_convert(from_obj)
      if self === from_obj
        from_obj
      else
        array = ::Array.try_convert( from_obj )
        new( array ) if array
      end
    end

    attr_reader :inner_array

    def initialize(inner_array = [])
      @inner_array = inner_array
    end

    def []=(index, value)
      inner_array[index] = value
    end

    def [](index)
      item = inner_array[ index ]

      MapWithIndifferentAccess.try_convert( item ) ||
        self.class.try_convert( item ) ||
        item
    end
  end

end
