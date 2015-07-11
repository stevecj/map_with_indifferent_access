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

  extend Forwardable

  attr_reader :inner_map

  def initialize(inner_map={})
    @inner_map = inner_map
  end

  def[]=(key, value)
    key = indifferent_key_from( key )
    inner_map[key] = value
  end

  def[](key)
    fetch(key, nil)
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

    self.class.try_convert( value ) ||
      self.class::Array.try_convert( value ) ||
      value
  end

  def expect_arity(arity, *args)
    unless arity === args.length
      raise ArgumentError, "wrong number of arguments (#{args.length} for #{arity})"
    end
  end

  def ==(other)
    return true if equal?( other )
    if other.respond_to?( :to_map_with_indifferent_access ) && other.respond_to?( :inner_map )
      return true if inner_map == other.inner_map
      return false if length == other.length
      each do |(key,value)|
        other_val = other.fetch(key) { return false }
        return false unless value = other_val
      end
    end
    true
  end

  def_delegators(
    :inner_map,
    :length,
    :size,
    :each_key,
  )

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
end
