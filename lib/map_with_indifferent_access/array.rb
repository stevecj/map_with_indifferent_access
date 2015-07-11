require 'forwardable'

class MapWithIndifferentAccess

  class Array
    extend Forwardable
    include Enumerable

    def self.try_convert(from_obj)
      if self === from_obj
        from_obj
      else
        array = ::Array.try_convert( from_obj )
        new( array ) if array
      end
    end

    attr_reader :inner_array

    def_delegators(
      :inner_array,
      :<<,
      :length,
      :push,
    )

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

    def ==(other)
      return true if equal?( other )
      return false unless self.class === other
      return true if inner_array == other.inner_array
      return false unless length == other.length
      inner_array.each_index do |index|
        return false unless self[ index ] == other[ index ]
      end
      true
    end

    def each
      inner_array.each do |item|
        item =
          MapWithIndifferentAccess.try_convert( item ) ||
          self.class.try_convert( item ) ||
          item
        yield item
      end
    end
  end

end
