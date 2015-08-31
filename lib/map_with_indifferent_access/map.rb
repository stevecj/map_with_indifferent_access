module MapWithIndifferentAccess

  class Map
    include MapWithIndifferentAccess::WithConveniences

    extend Forwardable
    include MapWithIndifferentAccess::WrapsCollection

    # Try to convert `from_obj` into a
    # {MapWithIndifferentAccess::Map}.
    #
    # @return [MapWithIndifferentAccess::Map]
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
    # Sets the default value in the target's {#inner_map} `Hash`.

    def_delegators(
      :inner_map,
      :default=,
      :keys,
      :rehash,
    )

    # Returns a new instance of {MapWithIndifferentAcces::Maps}
    # that encapsulates a new empty `::Array` or the `::Array`
    # coerced from the given `basis`.
    #
    # When a {MapWithIndifferentAccess::Map} is given as a basis,
    # this results on the given and new instances sharing the
    # same {#inner_map}. There is no obvious reason to do that on
    # purpose, but there is also no harm in allowing it to happen.
    #
    # @param [::Hash, MapWithIndifferentAccess::Map, Object] basis
    #   A `::Hash` or an object that can be implicitly coerced to
    #   a `::Hash`
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
    # `given_key` if that symbolization is a key in the
    # {#inner_map}.
    #
    # When `given_key` is a `Symbol` that is not a key in the
    # target's {#inner_map}, returns the stringification of
    # `given_key` if that stringification is a key in the
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
    # eplaced with the internalization of `value`.
    #
    # When `key` does not conform to a key in the target map, then
    # a new entry is added using the given `key` and the
    # internalization of `value`.
    #
    # @see #conform_key
    # @see MapWithIndifferentAccess::Values#internalize
    def[]=(key, value)
      value = MWIA::Values << value
      key = conform_key( key )
      inner_map[ key ] = value
    end

    alias store []=

    # Returns the externalization of the value from the target's
    # {#inner_map} entry having a key that conforms to the given
    # `key` if applicable.
    #
    # When there is no entry with a conforming key, returns the
    # externalization of the {#inner_map} `Hash`'s default value
    # for the given `key` (normally `nil`).
    def[](key)
      key = conform_key( key )
      value = inner_map[ key ]
      MWIA::Values >> value
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

      MWIA::Values >> value
    end

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

    def key(value)
      entry = rassoc( value )
      entry ? entry.first : nil
    end

    def default(key = nil)
      inner_default = inner_map.default( key )
      MWIA::Values >> inner_default
    end

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

    # When a block argument is given, calls the block once for each of the
    # target's entries, passing the entry's key and the externalization of
    # its value as a parameters, and then returns the target object.
    #
    # When no block argument is given, returns an enumerator.
    #
    # @return [MapWithIndifferentAccess::Map]
    def each
      return enum_for(:each ) unless block_given?

      each_key do |key|
        value = fetch( key )
        value = MWIA::Values >> value
        yield [key, value]
      end
    end

    alias each_pair each

    # When a block argument is given, calls the block once for each of the
    # target's keys, passing the key as a parameter, and then returns the
    # target object.
    #
    # When no block argument is given, returns an enumerator.
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
    # When no block argument is given, returns an enumerator.
    #
    # @return [MapWithIndifferentAccess::Map]
    def each_value
      return enum_for(:each_value) unless block_given?

      inner_map.each_value do |value|
        value = MWIA::Values >> value
        yield value
      end
      self
    end

    def delete(key)
      key = conform_key( key )
      value = if block_given?
        inner_map.delete( key ) { |key| yield key }
      else
        inner_map.delete( key )
      end
      MWIA::Values >> value
    end

    def reject
      return enum_for(:reject ) unless block_given?

      dup.delete_if{ |key, value|
        yield( key, value )
      }
    end

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

    def delete_if
      return enum_for(:delete_if ) unless block_given?

      inner_map.delete_if do |key, value|
        value = MWIA::Values >> value
        yield key, value
      end

      self
    end

    def select
      return enum_for(:select ) unless block_given?

      dup.keep_if{ |key, value|
        yield( key, value )
      }
    end

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

    def keep_if
      return enum_for(:keep_if ) unless block_given?

      inner_map.keep_if do |key, value|
        value = MWIA::Values >> value
        yield key, value
      end

      self
    end

    def replace(other)
      other_d = self.class.try_deconstruct( other ) || other
      inner_map.replace other_d
      return self
    end

    def assoc(obj)
      obj = conform_key( obj )
      entry = inner_map.assoc( obj )
      unless entry.nil?
        value = MWIA::Values >> entry[ 1 ]
        entry[ 1 ] = value
      end
      entry
    end

    def has_value?(value)
      value = MWIA::Values >> value
      each_value.any? { |v| v == value }
    end

    def rassoc(value)
      value = MWIA::Values >> value
      entry = inner_map.detect { |(k, v)|
        v = MWIA::Values >> v
        value == v
      }
      if entry
        entry[ 1 ] = MWIA::Values >> entry[ 1 ]
        entry
      else
        nil
      end
    end

    def merge(other)
      if block_given?
        dup.merge!( other ){ |*args| yield *args }
      else
        dup.merge!( other )
      end
    end

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

    def shift
      if inner_map.empty?
        MWIA::Values >> inner_map.shift
      else
        inner_result = inner_map.shift
        [
          inner_result[ 0 ],
          MWIA::Values >> inner_result[ 1 ]
        ]
      end
    end

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
