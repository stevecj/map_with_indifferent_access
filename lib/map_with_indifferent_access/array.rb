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

    def self.try_deconstruct(obj)
      if self === obj
        obj.inner_array
      elsif obj.respond_to?(:to_ary )
        a = obj.to_ary
        ::Array === a ? a : nil
      else
        nil
      end
    end

    attr_reader :inner_array

    def_delegators(
      :inner_array,
      :length,
    )

    def initialize(basis = [])
      basis = basis.inner_array if self.class === basis
      basis = basis.to_ary
      @inner_array = basis
    end

    def []=(index, value)
      value = MWIA::Values << value
      inner_array[ index ] = value
    end

    def [](index)
      item = inner_array[ index ]
      MWIA::Values >> item
    end

    alias at []

    def fetch(index, *args)
      item =
        if block_given?
          inner_array.fetch( index, *args ){ |idx| yield idx }
        else
          inner_array.fetch( index, *args )
        end
      MWIA::Values >> item
    end

    def <<(value)
      value = MWIA::Values << value
      inner_array << value
    end

    def push(*values)
      values.each do |value|
        self << value
      end
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
        item = MWIA::Values >> item
        yield item
      end
    end
  end

end
