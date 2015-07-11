require "map_with_indifferent_access/version"
require "map_with_indifferent_access/array"
require 'forwardable'

class MapWithIndifferentAccess
  extend Forwardable

  attr_reader :inner_map

  def initialize(inner_map={})
    @inner_map = inner_map
  end

  def[]=(key, value)
    if inner_map.key?( key )
      # Use given key
    elsif String === key
      key_sym = key.to_sym
      key = key_sym if inner_map.key?( key_sym )
    elsif Symbol === key
      key_string = "#{key}"
      key = key_string if inner_map.key?( key_string )
    end
    inner_map[key] = value
  end

  def[](key)
    value = if inner_map.key?( key )
      inner_map[ key ]
    elsif String === key
      inner_map[key.to_sym]
    elsif Symbol === key
      inner_map["#{key}"]
    end
    unless self.class === value || self.class::Array === value
      if value.respond_to?( :to_hash )
        value = self.class.new( value )
      elsif value.respond_to?( :to_ary )
        value = self.class::Array.new( value )
      end
    end
    value
  end

  def fetch(key, *more_args)
    unless (0..1) === more_args.length
      raise ArgumentError, "wrong number of arguments (#{more_args.length + 1} for 1..2)"
    end
    if block_given? && !more_args.empty?
      warn "#{__FILE__}:#{__LINE__}: warning: block supersedes default value argument"
    end
    value = if inner_map.key?( key )
      inner_map[ key ]
    elsif String === key
      key_sym = key.to_sym
      if inner_map.key?( key_sym )
        inner_map[ key_sym ]
      elsif block_given?
        yield key
      elsif !more_args.empty?
        more_args.first
      else
        raise KeyError, "key not found: #{key.inspect}"
      end
    elsif Symbol === key
      key_string = "#{key}"
      if inner_map.key?( key_string )
        inner_map[ key_string ]
      elsif block_given?
        yield key
      elsif !more_args.empty?
        more_args.first
      else
        raise KeyError, "key not found: #{key.inspect}"
      end
    elsif block_given?
      yield key
    elsif !more_args.empty?
      more_args.first
    else
      raise KeyError, "key not found: #{key.inspect}"
    end
    unless self.class === value || self.class::Array === value
      if value.respond_to?( :to_hash )
        value = self.class.new( value )
      elsif value.respond_to?( :to_ary )
        value = self.class::Array.new( value )
      end
    end
    value
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

end
