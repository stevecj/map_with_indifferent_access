module MapWithIndifferentAccess

  module Values
    include MapWithIndifferentAccess::WithConveniences

    extend self

    def externalize(obj)
      (
        MWIA::Map.try_convert( obj ) ||
        MWIA::List.try_convert( obj ) ||
        obj
      )
    end

    alias >> externalize

    def internalize(obj)
      (
        MWIA::Map.try_deconstruct( obj ) ||
        MWIA::List.try_deconstruct( obj ) ||
        obj
      )
    end

    alias << internalize
  end

end

