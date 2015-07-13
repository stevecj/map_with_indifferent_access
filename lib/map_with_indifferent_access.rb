require "map_with_indifferent_access/version"
require "map_with_indifferent_access/array"
require 'forwardable'

class MapWithIndifferentAccess

  def self.try_convert(from_obj)
    if self === from_obj
      from_obj
    else
      hash = Hash.try_convert( from_obj )
      new( hash ) if hash
    end
  end

  def self.[](obj)
    try_convert( obj ) || self::Array.try_convert( obj ) || obj
  end

  extend Forwardable
  include Enumerable

  attr_reader :inner_map

  def_delegators(
    :inner_map,
    :clear,
    :each_key,
    :length,
    :size,
  )

  def initialize(basis={})
    use_basis = basis
    use_basis = basis.inner_map if self.class === basis
    use_basis = Hash.try_convert( use_basis )
    raise ArgumentError, "Could not convert #{basis.inspect} into a Hash" unless use_basis
    @inner_map = use_basis
  end

  def[]=(key, value)
    key = indifferent_key_from( key )
    inner_map[key] = value
  end

  def[](key)
    fetch(key)
  end

  def fetch(key, *more_args)
    expect_arity 1..2, key, *more_args
    if block_given? && !more_args.empty?
      warn "#{caller[0]}: warning: block supersedes default value argument"
    end

    indifferent_key = indifferent_key_from( key )

    value = if inner_map.key?( indifferent_key )
      inner_map.fetch( indifferent_key )
    elsif block_given?
      inner_map.fetch( key ) {|key| yield key }
    else
      inner_map.fetch( key, *more_args )
    end

    self.class[ value ]
  end

  def ==(other)
    return true if equal?( other )
    other = self.class.try_convert( other )
    return false unless other

    return true if inner_map == other.inner_map
    return false if length != other.length
    each do |(key,value)|
      other_val = other.fetch(key) { return false }
      return false unless value == other_val
    end

    true
  end

  def each
    return enum_for(:each) unless block_given?

    each_key do |key|
      value = fetch( key )
      value = self.class[ value ]
      yield [key, value]
    end
  end

  alias each_pair each

  def each_value
    return enum_for(:each_value) unless block_given?

    inner_map.each_value do |value|
      value = self.class[ value ]
      yield value
    end
  end

  def delete(key)
    key = indifferent_key_from( key )
    value = if block_given?
      inner_map.delete( key ) { |key| yield key }
    else
      inner_map.delete( key )
    end
    self.class[ value ]
  end

  def assoc(obj)
    obj = indifferent_key_from( obj )
    entry = inner_map.assoc( obj )
    unless entry.nil?
      value = self.class[ entry[1] ]
      entry[1] = value
    end
    entry
  end

  private

  def indifferent_key_from(given_key)
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

  def expect_arity(arity, *args)
    unless arity === args.length
      raise ArgumentError, "wrong number of arguments (#{args.length} for #{arity})"
    end
  end

end
