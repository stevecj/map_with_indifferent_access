require "map_with_indifferent_access/version"

class MapWithIndifferentAccess
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
    if inner_map.key?( key )
      inner_map[ key ]
    elsif String === key
      inner_map[key.to_sym]
    elsif Symbol === key
      inner_map["#{key}"]
    end
  end
end
