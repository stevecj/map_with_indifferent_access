require 'forwardable'

class MapWithIndifferentAccess

  module WrapsCollection
    extend Forwardable
    include MapWithIndifferentAccess::WithConveniences
    include Enumerable

    # @!method frozen?
    # Returns `true` when the target/wrapper is frozen, in which
    # case, its #inner_collection is also frozen.
    # Returns `false` when the target/wrapper is not frozen, in
    # which case, its #inner_collection might or might not be
    # frozen.
    alias _frozen? frozen?

    # @!method tainted?
    # Reflects the tainted-ness of its #inner_collection.

    # @!method untrusted?
    # Reflects the untrusted-ness of its #inner_collection.

    # @!method frozen?
    # Reflects the frozen-ness of its #inner_collection.
    # When `true`, the #inner_collection is frozen, and the
    # target/wrapper might be frozen or not.
    # When `false`, the #inner_collection is not frozen, and
    # neither is the target/wrapper.
    # When the #inner_collection is frozen, but not the target,
    # then the target behaves as if frozen for the most part,
    # however some of the restrictions that Ruby applies to
    # truly frozen objects do not apply, such as preventing
    # instance methods from being dynamically added to the
    # object.

    def_delegators(
      :inner_collection,
      :length,
      :size,
      :clear,
      :empty?,
      :tainted?,
      :untrusted?,
      :frozen?,
    )

    # @!method taint
    # Causes the target's #inner_collection to be tainted.

    # @!method untaint
    # Causes the target's #inner_collection to be untainted.

    # @!method untrust
    # Causes the target's #inner_collection to be untrusted.

    # @!method trust
    # Causes the target's #inner_collection to be trusted.

    [:taint, :untaint, :untrust, :trust ].each do |method_name|
      class_eval <<-EOS, __FILE__, __LINE__ + 1
        def #{method_name}
          inner_collection.#{method_name}
          self
        end
      EOS
    end

    # @!method freeze
    # Freezes both the target map and its #inner_map [Hash].
    def freeze
      super
      inner_collection.freeze
      self
    end
  end

end
