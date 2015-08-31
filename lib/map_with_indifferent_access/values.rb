class MapWithIndifferentAccess

  module Values
    include MapWithIndifferentAccess::WithConveniences

    extend self

    def externalize(obj)
      (
        MWIA.try_convert( obj ) ||
        MWIA::List.try_convert( obj ) ||
        obj
      )
    end

    alias >> externalize

    def internalize(obj)
      (
        MWIA.try_deconstruct( obj ) ||
        MWIA::List.try_deconstruct( obj ) ||
        obj
      )
    end

    alias << internalize
  end

end

