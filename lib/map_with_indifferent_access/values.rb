class MapWithIndifferentAccess

  module Values
    include MapWithIndifferentAccess::WithConveniences

    extend self

    def externalize(obj)
      (
        MWIA.try_convert( obj ) ||
        MWIA::Array.try_convert( obj ) ||
        obj
      )
    end

    alias >> externalize

    def internalize(obj)
      (
        MWIA.try_deconstruct( obj ) ||
        MWIA::Array.try_deconstruct( obj ) ||
        obj
      )
    end

    alias << internalize
  end

end

