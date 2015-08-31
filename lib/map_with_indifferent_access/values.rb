module MapWithIndifferentAccess

  module Values
    extend self

    def externalize(obj)
      (
        Map.try_convert( obj ) ||
        List.try_convert( obj ) ||
        obj
      )
    end

    alias >> externalize

    def internalize(obj)
      (
        Map.try_deconstruct( obj ) ||
        List.try_deconstruct( obj ) ||
        obj
      )
    end

    alias << internalize
  end

end

