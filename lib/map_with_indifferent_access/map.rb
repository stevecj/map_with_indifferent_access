module MapWithIndifferentAccess

  class Map
    extend Forwardable
    include MapWithIndifferentAccess::WrapsCollection

    # Try to convert `from_obj` into a {Map}.
    #
    # @return [Map]
    #   converted object if `from_obj` is convertible.
    #
    # @return [nil]
    #   if `from_obj` cannot be converted for any reason.
    def self.try_convert(from_obj)
      if self === from_obj
        from_obj
      else
        hash = Hash.try_convert( from_obj )
        new( hash ) if hash
      end
    end

    # Try to convert `obj`, which might be a {Map} into a `Hash`.
    #
    # @return [Hash]
    #   converted object if `obj` is convertible.
    #
    # @return [nil]
    #   if `obj` cannot be converted for any reason.
    def self.try_deconstruct(obj)
      if self === obj
        obj.inner_map
      elsif obj.respond_to?(:to_hash )
        h = obj.to_hash
        Hash === h ? h : nil
      else
        nil
      end
    end

    # The encapsuated `Hash` object.
    attr_reader :inner_map
    alias inner_collection inner_map

    # @!method default=(other)
    #   Sets the default value in the target's {#inner_map} `Hash`.

    # @!method keys
    #  Returns a new `Array` populated with the keys from this
    #  {Map}.
    #
    #  @return [Array]
    #  @see #values

    # @!method rehash
    #   Rebuilds the target's {#inner_map} `Hash` based on the
    #   current `#hash` values for each key. If values of key
    #   objects have changed since they were inserted, this will
    #   re-index that `Hash`.
    #
    #   If {#rehash} is called while an iterator is traversing
    #   the {Map} or its {#inner_map} `Hash`, a `RuntimeError` will
    #   be raised in the iterator.
    #
    #   @return [Map]

    def_delegators(
      :inner_map,
      :default=,
      :keys,
      :rehash,
    )

    # Initializes a new {Map} that encapsulates a new
    # empty `Array` or the `Array` coerced from the given
    # `basis`.
    #
    # When a {Map} is given as a basis, this results on the given
    # and new instances sharing the same {#inner_map}. There is
    # no obvious reason to do that on purpose, but there is also
    # no likely harm in allowing it to happen.
    #
    # @param [::Hash, MapWithIndifferentAccess::Map, Object] basis
    #   A `Hash` or an object that can be implicitly coerced to a
    #   `::Hash`
    def initialize(basis={})
      use_basis = basis
      use_basis = basis.inner_map if self.class === basis
      use_basis = Hash.try_convert( use_basis )
      raise ArgumentError, "Could not convert #{basis.inspect} into a Hash" unless use_basis
      @inner_map = use_basis
    end

    # Returns the `given_key` object if it is a key in the target's
    # {#inner_map} `Hash` or if neither `given_key` nor its
    # `String`/`Symbol` alternative is a key in the {#inner_map}.
    #
    # When `given_key` is a `String` that is not a key in the
    # target's {#inner_map}, returns the symbolization of
    # `given_key` if that symbolization _is_ a key in the
    # {#inner_map}.
    #
    # When `given_key` is a `Symbol` that is not a key in the
    # target's {#inner_map}, returns the stringification of
    # `given_key` if that stringification _is_ a key in the
    # {#inner_map}.
    def conform_key(given_key)
      case given_key
      when String
        alt_key = inner_map.key?( given_key ) ? given_key : given_key.to_sym
        inner_map.key?( alt_key ) ? alt_key : given_key
      when Symbol
        alt_key = inner_map.key?( given_key ) ? given_key : "#{given_key}"
        inner_map.key?( alt_key ) ? alt_key : given_key
      else
        given_key
      end
    end

    # Creates an entry or replaces the value of an existing entry
    # in the target's {#inner_map} `Hash`.
    #
    # When the `key` conforms to a key in the target map, then the
    # value of the matching entry in the target's {#inner_map} is 
    # replaced with the internalization of `value`.
    #
    # When `key` does not conform to a key in the target map, then
    # a new entry is added using the given `key` and the
    # internalization of `value`.
    #
    # Returns the given `value`.
    #
    # @see #conform_key
    # @see Values.internalize
    def[]=(key, value)
      key = conform_key( key )
      intern_value = Values << value
      inner_map[ key ] = intern_value
      value
    end

    alias store []=

    # Returns the externalization of the value from the target's
    # {#inner_map} entry having a key that conforms to the given
    # `key` if applicable.
    #
    # When there is no entry with a conforming key, returns the
    # externalization of the {#inner_map} `Hash`'s default value
    # for the given `key` (normally `nil`).
    #
    # @see #conform_key
    # @see Values.externalize
    def[](key)
      key = conform_key( key )
      value = inner_map[ key ]
      Values >> value
    end

    def fetch(key, *more_args)
      expect_arity 1..2, key, *more_args
      if block_given? && !more_args.empty?
        warn "#{caller[ 0 ]}: warning: block supersedes default value argument"
      end

      conformed_key = conform_key( key )

      value = if inner_map.key?( conformed_key )
        inner_map.fetch( conformed_key )
      elsif block_given?
        inner_map.fetch( key ) {|key| yield key }
      else
        inner_map.fetch( key, *more_args )
      end

      Values >> value
    end

    # Returns `true` if the conformation of `key` is present in
    # the target {Map}.
    #
    # @return [Boolean]
    def key?(key)
      case key
      when String
        inner_map.key?( key ) || inner_map.key?( key.to_sym )
      when Symbol
        inner_map.key?( key ) || inner_map.key?("#{key}")
      else
        inner_map.key?( key )
      end
    end

    alias has_key? key?
    alias include? key?
    alias member?  key?

    # Returns the key for an entry, the externalization of which
    # is equal to the externalization of `value`. Returns `nil`
    # if no match is found.
    #
    # @return [Object, nil]
    #
    # @see Values.externalize
    def key(value)
      entry = rassoc( value )
      entry ? entry.first : nil
    end

    # Returns the default value, the value that would be returned
    # by `<target>[key]` if the conformation of `key` did not exist
    # in the target.
    #
    # @see #conform_key
    def default(key = nil)
      inner_default = inner_map.default( key )
      Values >> inner_default
    end

    # Returns `true` if the entries in `other` (a {Map}, `Hash`,
    # or other `Hash`-like object) are equal in numer and
    # equivalent to the entries in the target {Map}.
    #
    # Entries are equivalent if their keys are equivalent with
    # `String`/`Symbolic` indifference and their externalized
    # values are equal using `==`.
    #
    # @return [Boolean]
    def ==(other)
      return true if equal?( other )
      other = self.class.try_convert( other )
      return false unless other

      return true if inner_map == other.inner_map
      return false if length != other.length
      each do |(key, value)|
        other_val = other.fetch(key) { return false }
        return false unless value == other_val
      end

      true
    end

    # When a block argument is given, calls the block once for
    # each of the target's entries, passing the entry's key and
    # externalized value as parameters, and then returns the
    # target object.
    #
    # When no block argument is given, returns an `Enumerator`.
    #
    # @overload each
    #   @yieldparam key
    #   @yieldparam value
    #   @return [MapWithIndifferentAccess::Map]
    #
    # @overload each
    #   @return [Enumerator]
    def each
      return enum_for(:each ) unless block_given?

      each_key do |key|
        value = fetch( key )
        value = Values >> value
        yield [key, value]
      end
    end

    alias each_pair each

    # When a block argument is given, calls the block once for each of the
    # target's keys, passing the key as a parameter, and then returns the
    # target object.
    #
    # When no block argument is given, returns an `Enumerator`.
    #
    # @return [MapWithIndifferentAccess::Map]
    def each_key
      return enum_for(:each_key ) unless block_given?
      inner_map.each_key do |key|
        yield key
      end
      self
    end

    # When a block argument is given, calls the block once for each of the
    # target's entries, passing externalization the entry value as a parameter,
    # and then returns the target.
    #
    # When no block argument is given, returns an `Enumerator`.
    #
    # @return [MapWithIndifferentAccess::Map]
    def each_value
      return enum_for(:each_value) unless block_given?

      inner_map.each_value do |value|
        value = Values >> value
        yield value
      end
      self
    end

    # Returns a {List} containing the entry values from the target {Map}.
    #
    # @return [List]
    def values
      List.new( inner_map.values )
    end

    # Delete the externalization of the value associated with the
    # conformation of the given `key` or default value.
    #
    # @overload delete(key)
    #   Returns the externalization of the value returned from
    #   the {#inner_map} `Hash` on deletion.
    #
    # @overload delete(key)
    #   @yieldparam key
    #
    #   Returns the externalization of the value returned by the
    #   given block for the given `key`.
    #
    # @see #conform_key
    # @see Values.externalize
    def delete(key)
      key = conform_key( key )
      value = if block_given?
        inner_map.delete( key ) { |key| yield key }
      else
        inner_map.delete( key )
      end
      Values >> value
    end

    # Returns a new {Map} consisting of entries for which the
    # block returns `false`, given the entry's key and
    # externalized value.
    #
    # If no block is given, then an `Enumerator` is returned
    # instead.
    #
    # @overload reject
    #   @yieldparam key
    #   @return [Map]
    #
    # @overload reject
    #   @return [Enumerator]
    #
    # @see Values.externalize
    def reject
      return enum_for(:reject ) unless block_given?

      dup.delete_if{ |key, value|
        yield( key, value )
      }
    end

    # Equivalent to {#delete_if}, but returns `nil` if no changes
    # were made.
    #
    # @overload reject!
    #   @yieldparam key
    #   @yieldparam value
    #   @return [Map, nil]
    #
    # @overload reject!
    #   @return [Enumerator]
    #
    # @see #delete_if
    def reject!
      return enum_for(:reject!) unless block_given?

      has_rejections = false
      delete_if{ |key, value|
        is_rejected = yield( key, value )
        has_rejections ||= is_rejected
        is_rejected
      }

      has_rejections ? self : nil
    end

    # Deletes every entry for which the block evaluates to
    # `true` given the entry's key and externalized value.
    #
    # If no block is given, then an `Enumerator` is returned
    # instead.
    #
    # @overload delete_if
    #   @yieldparam key
    #   @yieldparam value
    #   @return [Map]
    #
    # @overload delete_if
    #   @return [Enumerator]
    #
    # @see Values.externalize
    def delete_if
      return enum_for(:delete_if ) unless block_given?

      inner_map.delete_if do |key, value|
        value = Values >> value
        yield key, value
      end

      self
    end

    # Returns a new {Map} consisting of entries for which the
    # block returns `true`, given the entry's key and
    # externalized value.
    #
    # If no block is given, then an `Enumerator` is returned
    # instead.
    #
    # @overload select
    #   @yieldparam key
    #   @return [Map]
    #
    # @overload select
    #   @return [Enumerator]
    #
    # @see Values.externalize
    def select
      return enum_for(:select ) unless block_given?

      dup.keep_if{ |key, value|
        yield( key, value )
      }
    end

    # Equivalent to {#keep_if}, but returns `nil` if no changes
    # were made.
    #
    # @overload select!
    #   @yieldparam key
    #   @yieldparam value
    #   @return [Map, nil]
    #
    # @overload select!
    #   @return [Enumerator]
    #
    # @see #keep_if
    def select!
      return enum_for(:select!) unless block_given?

      has_rejections = false
      keep_if{ |key, value|
        is_selected = yield( key, value )
        has_rejections ||= ! is_selected
        is_selected
      }

      has_rejections ? self : nil
    end

    # Deletes every entry for which the block evaluates to
    # `false`, given the entry's key and externalized value.
    #
    # If no block is given, then an `Enumerator` is returned
    # instead.
    #
    # @overload keep_if
    #   @yieldparam key
    #   @yieldparam value
    #   @return [Map]
    #
    # @overload keep_if
    #   @return [Enumerator]
    #
    # @see Values.externalize
    def keep_if
      return enum_for(:keep_if ) unless block_given?

      inner_map.keep_if do |key, value|
        value = Values >> value
        yield key, value
      end

      self
    end

    # Replace the contents of the target's {#inner_map} `Hash`
    # with the deconstruction of the given `Hash`-like object.
    #
    # @return [Map]
    #
    # @see .try_deconstruct
    def replace(other)
      other_d = self.class.try_deconstruct( other ) || other
      inner_map.replace other_d
      return self
    end

    # Searches through the map, comparing the conformation of
    # `obj` with each entry's key using `==`. Returns a 2-element
    # array containing the key and externalized value from the
    # matching element or returns or `nil` if no match is found.
    #
    # @return [Array, nil]
    #
    # @see #rassoc
    # @see #conform_key
    def assoc(obj)
      obj = conform_key( obj )
      entry = inner_map.assoc( obj )
      unless entry.nil?
        value = Values >> entry[ 1 ]
        entry[ 1 ] = value
      end
      entry
    end

    # Returns `true` if the internalization of `value` is present
    # for some key in the target.
    #
    # @return [Boolean]
    #
    # @see Values.internalize
    def has_value?(value)
      value = Values >> value
      each_value.any? { |v| v == value }
    end

    # Searches through the map, comparing the externalization of
    # `value` with the externalized value of each entry using
    # `==.` Returns a 2-element array containing the key and
    # externalized value from the matching element or returns or
    # `nil` if no match is found.
    #
    # @return [Array, nil]
    #
    # @see #assoc
    # @see Values.externalize
    def rassoc(value)
      value = Values >> value
      entry = inner_map.detect { |(k, v)|
        v = Values >> v
        value == v
      }
      if entry
        entry[ 1 ] = Values >> entry[ 1 ]
        entry
      else
        nil
      end
    end

    # Returns a new {Map} containing the contents of `other` (a
    # {Map}, `Hash`, or other `Hash`-like object) and of the
    # target {Map}.
    #
    # Each entry in `other` with key that is equivalent to a key
    # in the target (with `String`/`Symbol` indifference) is
    # treated as a collision.
    #
    # @overload merge(other)
    #   Each collision produces an entry with its key from the
    #   entry in target and its value from the entry in
    #   `other`.
    #
    # @overload merge(other)
    #   @yieldparam key
    #     The key from the target-side colliding entry.
    #
    #   @yieldparam oldval
    #     The externalization of value from the target-side
    #     colliding entry.
    #
    #   @yieldparam newval
    #     The externalization of value from the `other`-side
    #     colliding entry.
    #
    #   Each collision produces an entry with its key from the
    #   target-side entry and its value from the internalization
    #   of the block call result.
    #
    # @return [Map]
    #
    # @see #merge!
    # @see Values.externalize
    # @see Values.internalize
    def merge(other)
      if block_given?
        dup.merge!( other ){ |*args| yield *args }
      else
        dup.merge!( other )
      end
    end

    # Adds the contents of `other` (a {Map}, `Hash`, or other
    # `Hash`-like object) to the target {Map}.
    #
    # Each entry in `other` with key that is equivalent to a key
    # in the target (with `String`/`Symbol` indifference) is
    # treated as a collision.
    #
    # @overload merge!(other)
    #   Each collision produces an entry with its key from the
    #   entry in target and its value from the entry in
    #   `other`.
    #
    # @overload merge!(other)
    #   @yieldparam key
    #     The key from the target-side colliding entry.
    #
    #   @yieldparam oldval
    #     The externalization of value from the target-side
    #     colliding entry.
    #
    #   @yieldparam newval
    #     The externalization of value from the `other`-side
    #     colliding entry.
    #
    #   Each collision produces an entry with its key from the
    #   target-side entry and its value from the internalization
    #   of the block call result.
    #
    # @return [Map]
    #
    # @see #merge
    # @see Values.externalize
    # @see Values.internalize
    def merge!(other)
      other.each_pair do |(key, value)|
        key = conform_key( key )
        if block_given? && inner_map.key?(key)
          self[key] = yield( key, self[key], value )
        else
          self[key] = value
        end
      end
      self
    end

    alias update merge!

    # Removes an entry from the target {Map} and returns a 2-item
    # `Array` _`[ <key>, <externalized value> ]`_ or the
    # externalization of the {Map}'s default value if it is
    # empty.
    #
    # Yes, the behavior when the behavior for an empty {Map} with
    # a non-`nil` default is weird and troublesome, but it is
    # parallel to the similarly weird behavior of `Hash#shift`.
    #
    # @return [Array,Object]
    #
    # @see Values.externalize
    def shift
      if inner_map.empty?
        Values >> inner_map.shift
      else
        inner_result = inner_map.shift
        [
          inner_result[ 0 ],
          Values >> inner_result[ 1 ]
        ]
      end
    end

    # Returns a new {Map} with an {#inner_map} `Hash` created by
    # using the the target's {#inner_map}'s values as keys and
    # keys as values.
    #
    # @return [Map]
    def invert
      self.class.new( inner_map.invert )
    end

    private

    def expect_arity(arity, *args)
      unless arity === args.length
        raise ArgumentError, "wrong number of arguments (#{args.length} for #{arity})"
      end
    end

    def initialize_dup(orig)
      super
      @inner_map = inner_map.dup
    end

    def initialize_clone(orig)
      super
      @inner_map = inner_map.clone
    end
  end

end
