class MapWithIndifferentAccess

  class Array
    include MapWithIndifferentAccess::WithConveniences

    extend Forwardable
    include MWIA::WrapsCollection

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
    alias inner_collection inner_array

    def initialize(basis = [])
      basis = basis.inner_array if self.class === basis
      basis = basis.to_ary
      @inner_array = basis
    end

    def []=(index, length_or_value, *maybe_value)
      arg_count = 2 + maybe_value.length
      unless (2..3) === arg_count
        raise ArgumentError, "wrong number of arguments (#{arg_count} for 2..3)"
      end

      if maybe_value.empty?
        maybe_length = []
        value_or_values = length_or_value
      else
        maybe_length = [length_or_value]
        value_or_values = maybe_value.first
      end

      if (
        ( !maybe_length.empty? || Range === index ) &&
        ( value_array = MWIA::Array.try_deconstruct( value_or_values ) )
      )
        value_array = value_array.map{ |v| MWIA::Values << v }
        inner_array[ index, *maybe_length ] = value_array
      else
        value = MWIA::Values << value_or_values
        inner_array[ index, *maybe_length ] = value
      end
    end

    def [](index, *maybe_length)
      arg_count = 1 + maybe_length.length
      unless (1..2) === arg_count
        raise ArgumentError, "wrong number of arguments (#{arg_count} for 1..2)"
      end

      if !maybe_length.empty? || Range === index
        value_array = inner_array[ index, *maybe_length ]
        value_array.map!{ |v| MWIA::Values >> v }
        MWIA::Array.new( value_array )
      else
        value = inner_array[ index ]
        MWIA::Values >> value
      end
    end

    def at(index)
      item = inner_array.at( index )
      MWIA::Values >> item
    end

    def <<(value)
      value = MWIA::Values << value
      inner_array << value
      self
    end

    def push(*values)
      values.map!{ |v| MWIA::Values << v }
      inner_array.push *values
      self
    end

    def unshift(*values)
      values.map!{ |v| MWIA::Values << v }
      inner_array.unshift *values
      self
    end

    def insert(index, *values)
      values.map!{ |v| MWIA::Values << v }
      inner_array.insert(index, *values)
      self
    end

    def values_at(*indexes)
      inner_result = inner_array.values_at( *indexes )
      MWIA::Values >> inner_result
    end

    def fetch(index, *args)
      item =
        if block_given?
          inner_array.fetch( index, *args ){ |idx| yield idx }
        else
          inner_array.fetch( index, *args )
        end
      MWIA::Values >> item
    end

    def shift(*maybe_n)
      arg_count = maybe_n.length
      unless (0..1) === arg_count
        raise ArgumentError, "wrong number of arguments (#{arg_count} for 0..1)"
      end
      if maybe_n.empty?
        MWIA::Values >> inner_array.shift
      else
        inner_result = inner_array.shift( *maybe_n )
        MWIA::Array.new( inner_result )
      end
    end

    def pop(*maybe_n)
      arg_count = maybe_n.length
      unless (0..1) === arg_count
        raise ArgumentError, "wrong number of arguments (#{arg_count} for 0..1)"
      end
      if maybe_n.empty?
        MWIA::Values >> inner_array.pop
      else
        inner_result = inner_array.pop( *maybe_n )
        MWIA::Array.new( inner_result )
      end
    end

    def delete_at(index)
      inner_result = inner_array.delete_at( index )
      MWIA::Values >> inner_result
    end

    def delete(obj)
      obj = MWIA::Values >> obj
      removed_items = false
      result = nil
      inner_array.delete_if{ |v|
        v = MWIA::Values >> v
        if v == obj
          result = v
          removed_items = true
          true
        end
      }
      if !removed_items && block_given?
        result = MWIA::Values >> yield( obj )
      end
      result
    end

    def uniq
      dup.uniq!
    end

    def_delegator :inner_array, :uniq!

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
