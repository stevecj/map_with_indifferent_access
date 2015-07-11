require "map_with_indifferent_access/version"

class MapWithIndifferentAccess
  attr_reader :inner_map

  def initialize
    @inner_map = {}
  end

  def[]=(key, value)
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
