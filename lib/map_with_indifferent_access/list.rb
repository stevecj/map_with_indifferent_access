module MapWithIndifferentAccess

  class List
    extend Forwardable
    include MapWithIndifferentAccess::WrapsCollection

    # Try to convert `from_obj` into a {List}.
    #
    # @return [List]
    #   converted object if `from_obj` is convertible.
    #
    # @return [nil]
    #   if `from_obj` cannot be converted for any reason.
    def self.try_convert(from_obj)
      if self === from_obj
        from_obj
      else
        array = ::Array.try_convert( from_obj )
        new( array ) if array
      end
    end

    # Try to convert `obj`, which might be a {List} into an
    # `Array`.
    #
    # @return [Array]
    #   converted object if `obj` is convertible.
    #
    # @return [nil]
    #   if `obj` cannot be converted for any reason.
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

    # The encapsuated `::Array` object.
    attr_reader :inner_array
    alias inner_collection inner_array

    # Initializes a new instance of {List} that encapsulates a
    # new empty `Array` or the `Array` coerced from the given
    # `basis`.
    #
    # When a {List} is given as a `basis`, this results on the
    # given and new instances sharing the same {#inner_array}.
    # There is no obvious reason to do that on purpose, but there
    # is also no particular harm in allowing it to happen.
    #
    # @param [Array, List, Object] basis
    #   An `Array` or an object that can be implicitly coerced to
    #   an `Array`
    def initialize(basis = [])
      use_basis = basis
      use_basis = basis.inner_array if self.class === basis
      use_basis = ::Array.try_convert( use_basis )
      raise ArgumentError, "Could not convert #{basis.inspect} into an ::Array" unless use_basis
      @inner_array = use_basis
    end

    # Element Assignment — Sets the element at index, or replaces
    # a subarray from the start index for length elements, or
    # replaces a subarray specified by the range of indices.
    #
    # The given object or array is internalized befor being
    # ussed for assignment into the {#inner_array}.
    #
    # @return the given value or array.
    #
    # @see Values.internalize
    # @see #push
    # @see #unshift
    #
    # @overload []=(index, value)
    #   @param index [Fixnum]
    #   @param value [Object]
    #
    # @overload []=(start, length, array_or_value)
    #   @param start [Fixnum]
    #   @param length [Fixnum]
    #   @param array_or_value [Array, List Object, nil]
    #
    # @overload []=(range, array_or_value)
    #   @param range [Ramge]
    #   @param array_or_value [Array, List, Object, nil]
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
        ( value_array = List.try_deconstruct( value_or_values ) )
      )
        value_array = value_array.map{ |v| Values << v }
        inner_array[ index, *maybe_length ] = value_array
      else
        value = Values << value_or_values
        inner_array[ index, *maybe_length ] = value
      end
    end

    # @!method []
    #   Returns the element at index, or returns a subarray
    #   starting at the start index and continuing for length
    #   elements, or returns a subarray specified by range of
    #   indices.
    #
    #   Externalizes the result before returning it.
    #
    #   @see Values.externalize
    #
    #   @overload [](index)
    #     @param index [Fixnum]
    #     @return [Object]
    #
    #   @overload [](start, length)
    #     @param start [Fixnum]
    #     @param length [Fixnum]
    #     @return [List]
    #
    #   @overload [](range)
    #     @param range [Range]
    #     @return [List]
    #
    #   @overload slice(index)
    #     @param index [Fixnum]
    #     @return [Object]
    #
    #   @overload slice(start, length)
    #     @param start [Fixnum]
    #     @param length [Fixnum]
    #     @return [List]
    #
    #   @overload slice(range)
    #     @param range [Range]
    #     @return [List]

    ['[]', 'slice'].each do |method_name|
      class_eval <<-EOS, __FILE__, __LINE__ + 1

        def #{method_name}(index, *maybe_length)
          arg_count = 1 + maybe_length.length
          unless (1..2) === arg_count
            raise ArgumentError, "wrong number of arguments (\#{arg_count} for 1..2)"
          end

          if !maybe_length.empty? || Range === index
            value_array = inner_array.#{method_name}( index, *maybe_length )
            value_array.map!{ |v| Values >> v }
            List.new( value_array )
          else
            value = inner_array.#{method_name}( index )
            Values >> value
          end
        end

      EOS
    end

    # Returns the externalization of the element at `index`. A
    # negative index counts from the end of the list. Returns
    # `nil` if the index is out of range.
    #
    # @see #[]
    def at(index)
      item = inner_array.at( index )
      Values >> item
    end

    # Append. Pushes the given object on to the end of the list.
    # Returns the array itself, so several appends may be chained
    # together.
    #
    # Internalizes the given onject before appending it to the
    # target's {#inner_array}.
    #
    # @return [List]
    # @see #push
    def <<(value)
      value = Values << value
      inner_array << value
      self
    end

    # Append. Pushes the given object(s) on to the end of the
    # list. Returns the array itself, so several appends may be
    # chained together.
    #
    # Internalizes each given object before appending it to the
    # target's {#inner_array}.
    #
    # @return [List]
    # @see #<<
    # @see #pop
    # @see Values.internalize
    def push(*values)
      values.map!{ |v| Values << v }
      inner_array.push *values
      self
    end

    # Prepends objects to the front of the list, moving other
    # elements upwards.
    #
    # Internalizes each value before prepending it to the
    # target's {#inner_array}.
    #
    # See also {#shift} for the opposite effect.
    #
    # @return [List]
    # @see #shift
    # @see Values.internalize
    def unshift(*values)
      values.map!{ |v| Values << v }
      inner_array.unshift *values
      self
    end

    # Inserts the given values before the element with the given
    # index.
    #
    # Internalizes the values before inserting them into the
    # target's {#inner_array}.
    #
    # Negative indices count backwards from the end of the array,
    # where -1 is the last element. If a negative index is used,
    # the given values will be inserted after that element, so
    # using an index of -1 will insert the values at the end of
    # the list.
    #
    # @return [List]
    # @see Values.internalize
    def insert(index, *values)
      values.map!{ |v| Values << v }
      inner_array.insert(index, *values)
      self
    end

    # Returns a {List} containing the elements in self
    # corresponding to the given selector(s).
    #
    # The selectors may be either `Integer` indices or
    # `Range`s.
    #
    # @return List
    def values_at(*indexes)
      inner_result = inner_array.values_at( *indexes )
      Values >> inner_result
    end

    # Tries to retrieve the element at position `index`, but
    # raises an `IndexError` exception or uses a default value
    # when an invalid index is referenced.
    #
    # Returns the externalization of the retrieved value.
    #
    # @see MapWithIndifferentAccess::Values.externalize
    #
    # @overload fetch(index)
    #   Tries to retrieve the element at position `index`, but
    #   raises an `IndexError` exception if the referenced index
    #   lies outside of the array bounds.
    #
    #   @raise [IndexError]
    #
    # @overload fetch(index, default)
    #   Tries to retrieve the element at position `index`, but
    #   uses the given default if the referenced index lies
    #   outside of the array bounds.
    #
    # @overload fetch(index)
    #   @yieldparam index
    #   Tries to retrieve the element at position `index`, but if
    #   the referenced index lies outside of the array bounds,
    #   calls the given block, and uses the block call result.
    def fetch(index, *args)
      item =
        if block_given?
          inner_array.fetch( index, *args ){ |idx| yield idx }
        else
          inner_array.fetch( index, *args )
        end
      Values >> item
    end

    # Removes and returns the first element or first `n` elements
    # of the array, shifting all of the other elements downward.
    #
    # Returns the externalization of the removed element or array
    # of elements
    #
    # See {#unshift} for the opposite effect.
    #
    # @see Values.externalize
    #
    # @overload shift()
    #   Removes the first element and returns it, shifting all
    #   other elements down by one. Returns nil if the array is
    #   empty.
    #
    #   @return [Object, nil]
    #
    # @overload shift(n)
    #   Returns a {List} of the first `n` elements (or less) just
    #   like `array.slice!(0, n)` does, but also removing those
    #   elements from the target.
    #
    #   @return [List]
    def shift(*maybe_n)
      arg_count = maybe_n.length
      unless (0..1) === arg_count
        raise ArgumentError, "wrong number of arguments (#{arg_count} for 0..1)"
      end
      if maybe_n.empty?
        Values >> inner_array.shift
      else
        inner_result = inner_array.shift( *maybe_n )
        List.new( inner_result )
      end
    end

    # Removes and returns the last element or last `n` elements
    # of the array.
    #
    # Returns the externalization of the removed element or array
    # of elements
    #
    # See {#push} for the opposite effect.
    #
    # @see MapWithIndifferentAccess::Values.externalize
    #
    # @overload pop()
    #   Removes the last element and returns it. Returns nil if
    #   the array is empty.
    #
    #   @return [Object, nil]
    #
    # @overload pop(n)
    #   Returns a {MapWithIndifferentAccess::List} of the last
    #   `n` elements (or less) just like `array.slice!(-n, n)`
    #   does, but also removing those elements from the target.
    #
    #   @param n [Fixnum]
    #   @return [MapWithIndifferentAccess::List]
    def pop(*maybe_n)
      arg_count = maybe_n.length
      unless (0..1) === arg_count
        raise ArgumentError, "wrong number of arguments (#{arg_count} for 0..1)"
      end
      if maybe_n.empty?
        Values >> inner_array.pop
      else
        inner_result = inner_array.pop( *maybe_n )
        List.new( inner_result )
      end
    end

    # Deletes the element at the specified `index`, returning the
    # externalization of that element, or `nil` if the index is
    # out of range.
    #
    # @param index [Fixnum]
    # @return [Object, nil]
    #
    # @see #slice
    # @see Values.externalize
    def delete_at(index)
      inner_result = inner_array.delete_at( index )
      Values >> inner_result
    end

    # @!method &(other)
    #   @param other [List, Array, Object]
    #   @return [List]
    #
    #   Set Intersection.  Returns a new {Liat} containing
    #   elements common to the target {List} and `other` (a
    #   `List` or other `Array`-like object), excluding any
    #   duplicate items.  The order is preserved from the
    #   original list.
    #
    #   It compares elements using their `#hash` and `#eql?`
    #   methods for efficiency.
    #
    #   Note that this does not recongnize items of `Map` type as
    #   equal just because they are equal by `#==`, which can be
    #   the case when they have equivalent keys that differ by
    #   `String`/`Symbol` type. You might therefore wish to call
    #   {#&} for lists that have first had their keys
    #   deeply-stringified or deeply-symbolized.

    # @!method |(other)
    #   @param other [List, Array, Object]
    #   @return [List]
    #
    #   Set Union.  Returns a new {List} by joining the target
    #   `List` with `other` (a `List` or other `Array`-like
    #   object), excluding any duplicates and preserving the
    #   order from the original `List`.
    #
    #   It compares elements using their `#hash` and `#eql?`
    #   methods for efficiency.
    #
    #   Note that this does not recongnize items of `Map` type as
    #   equal just because they are equal by `#==`, which can be
    #   the case when they have equivalent keys that differ by
    #   `String`/`Symbol` type. You might therefore wish to call
    #   {#|} for lists that have first had their keys
    #   deeply-stringified or deeply-symbolized.

    # @!method +(other)
    #   @param other [List, Array, Object]
    #   @return [List]
    #
    #   Concatenation.  Returns a new {List} built by
    #   concatenating `other` (a `List` or other `Array`-like
    #   object) to the target `List`.
    #
    #   @see concat

    # @!method -(other)
    #   @param other [List, Array, Object]
    #   @return [List]
    #
    #   Difference.  Returns a new {List} that is a copy of the
    #   original, removing any items that also appear in
    #   `other` (a `List` or other `Array`-like object).  The
    #   order is preserved from the original `List`.
    #
    #   It compares elements using their `#hash` and `#eql?`
    #   methods for efficiency.
    #
    #   Note that this does not recongnize items of `Map` type as
    #   equal just because they are equal by `#==`, which can be
    #   the case when they have equivalent keys that differ by
    #   `String`/`Symbol` type. You might therefore wish to call
    #   {#-} for lists that have first had their keys
    #   deeply-stringified or deeply-symbolized.

    %w( & | + - ).each do |method_name|
      class_eval <<-EOS, __FILE__, __LINE__ + 1

        def #{method_name}(other)
          other = self.class.try_deconstruct( other )
          inner_result = inner_array.#{method_name}(other)
          List.new( inner_result )
        end

      EOS
    end

    # @!method join(separator=$,)
    #   @param separator [String]
    #   @return [String]
    #
    #   Returns a string consisting of `String`-converted item
    #   values from the target `List` separated by the
    #   `separator` string.  If no `separator` or `nil` is given,
    #   uses the value of `$,` as the separator.  Treats a `nil`
    #   `$,` value as a blank string.
    #
    #   The items are not externalized before being converted to
    #   `String`s, so `my_map.join` is exactly equivalent to
    #   `my_map.inner_array.join`.
    #
    #   @see Array#join
    def_delegator :inner_array, :join

    # Repetition.
    #
    # @overload *(n_copies)
    #   @return [Map]
    #
    #   Returns a new `List` built by concatenating `n_copies`
    #   copies of itself together.
    #
    # @overload *(separator)
    #   @return [String]
    #
    #   Equivalent to `target_list.join(separator)`.
    def *(n_copies_or_separator)
      result = inner_array * n_copies_or_separator
      result = List.new( result ) if Array === result
      result
    end

    # Deletes all items from self, the externalizations of which
    # are equal to the externalization of `obj`.
    #
    # Returns the externalization of the last deleted item if
    # applicable.
    #
    # @see Values.externalize
    #
    # @overload delete(obj)
    #   Returns `nil` if no matching items are found.
    #
    # @overload delete(obj)
    #   @yield
    #   Returns the externalization of the block result is no
    #   matching items are found.
    def delete(obj)
      obj = Values >> obj
      removed_items = false
      result = nil
      inner_array.delete_if{ |v|
        v = Values >> v
        if v == obj
          result = v
          removed_items = true
          true
        end
      }
      if !removed_items && block_given?
        result = Values >> yield( obj )
      end
      result
    end

    # Returns a new instance with duplicate items omitted.
    # Items are considered equal if their `#hash` values are
    # equal and comparison using `#eql?` returns `true`.
    #
    # Note that this does not recongnize items of [Map] type as
    # equal just because they are equal by `#==`, which can be
    # the case when they have equivalent keys that differ by
    # [String]/[Symbol] type. You might therefore wish to call
    # {#uniq} on an instance that has first had its keys
    # deeply-stringified or deeply-symbolized.
    #
    # @return [List]
    #
    # @see #uniq!
    def uniq
      dup.uniq!
    end

    # Deletes duplicate items from the target's {#inner_array},
    # leaving only unique items remaining. Items are considered
    # equal if their `#hash` values are equal and comparison
    # using `#eql?` returns `true`.
    #
    # Note that this does not recongnize items of [Map] type as
    # equal just because they are equal by `#==`, which can be
    # the case when they have equivalent keys that differ by
    # [String]/[Symbol] type. You might therefore wish to call
    # {#uniq} on an instance that has first had its keys
    # deeply-stringified or deeply-symbolized.
    #
    # @return [List]
    #
    # @see #uniq
    def uniq!
      inner_array.uniq!
      self
    end

    # Equality. The target is equal to the given `Array`-like
    # object if both contain the same number of elements, and
    # externalizations of corresponding items in itself and the
    # given object are equal according to `#==`.
    #
    # @return [Boolean]
    #
    # @see Values.externalize
    def ==(other)
      same_class = self.class === other

      return false unless same_class || other.respond_to?(:to_ary )

      # Optimizations
      return true if equal?( other )
      return true if same_class && inner_array == other.inner_array

      return false unless length == other.length
      zip( other ).all? { |(v,other_v)| v == Values >> other_v }
    end

    # Calls the given block once for each item in the target's
    # {#inner_array}, passing the externalization of the item to
    # the block.
    #
    # @see MapWithIndifferentAccess::Values.externalize
    #
    # @overload each
    #   @yieldparam item
    #   @return [List]
    #
    # @overload each
    #   @return [Enumerator]
    def each
      inner_array.each do |item|
        item = Values >> item
        yield item
      end
    end

  end

end
