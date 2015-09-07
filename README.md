# MapWithIndifferentAccess

A wrapper around Hash that treats String and Symbol keys as interchangeable.

Note that this gem is still in early development stages and does not yet have
any released versions.

Provides a `HashWithIndifferentAccess::Map` class that acts as a wrapper
around a `Hash` and provides `String`/`Symbol` indifferent access to its
entries.

Also provides a `HashWithIndifferentAccess::List` class that acts as a wrapper
around an `Array` that exists within an encapsulated hierarchy of nested
`Hash`es and `Array`s.


## Comparison to ActiveSupport's HashWithIndifferentAccess

Behaves similarly to `HashWithIndifferentAccess` from ActiveSupport, but with
the following differences.

### Difference 1
As of this writing, in order to have `HashWithIndifferentAccess` work as
expected, it is necessary to load pretty much all of ActiveSupport, which
modifies the behavior of other classes in ways that you might or might not
want.

`MapWithIndifferentAccess` does not currently alter any of the standard Ruby
classes, but might make some minimal, cautious, and optional changes to
standard Ruby classes in future versions.

### Difference 2
When a Hash-type object is added as a value into a
`HashWithIndifferentAccess`, it is copied into a new
`HashWithIndifferentAccess` that is entirely independent of the provided
`Hash`.

When a Hash-type object is added as a value into a
`MapWithIndifferentAccess::Map`, on the other hand, it is directly stored and
then wrapped in another `MapWithIndifferentAccess::Map` during retrieval.
Writing values into the original `Hash` affects the content eventually seen in
the returned `Map` as one would expect.

Code:

    h = HashWithIndifferentAccess.new
    foo = ( h[:foo] ||= {} )
    foo[:bar] = 'BAR'
    puts h[:foo][:bar].inspect

Output:

    nil

Code:

    m = MapWithIndifferentAccess.new
    foo = ( m[:foo] ||= {} )
    foo[:bar] = 'BAR'
    puts m[:foo][:bar].inspect

Output:

    "BAR"

### Difference 3
When a `Hash` is added to an `Array` that is the value of an entry in a
`HashWithIndifferentAccess`, that `Hash` is automatically copied into a
`HashWithIndifferentAccess` that is independent of the original `Hash`.

When a `Hash` is added to an `Array` that is the value of an entry in a
`MapWithIndifferentAccess::Map`, the `Hash` is directly stored and then
wrapped in another `MapWithIndifferentAccess::Map` during retrieval.
Writing values into the original `Hash` affects the content eventually seen in
the returned `Map` as one would expect.


## Conformed Keys

When reading values from or writing values to `Map` entries by key, the given
key is not used directly.  Instead, a "conformed key" is derived, and that is
used to access the entry in the encapsulated `Hash`.

In most cases, the conformation of a key is simply the key, but if it is a
`String` that doesn't have a match and the symbolization of that `String`
_does_ have a match, then the conformation is the result of that symbolization.
Similarly, if the given key is a `Symbol` without a match, but the
stringification of that `Symbol` does have a match, then the conformation is
the result of that stringification.


## Value Internalization and Externalization

An internal nested structure of `Hash`es and `Array`s is seen externally as a
nested structure of `Map`s and `List`s.  Assigning a `Map` or `Lists as a
value or item in other `Map` or `List` results in  corresponding `Hash` or
`Array` being placed into the encapsulated collection.  Retrieving an entry
value or item that is internally stored as a `Hash` or `Array` from a `Map` or
`List` results in a `Map` or `List` that encapsulates the underlying
entry/item value.

To be more specific...

When a `Map` _(B)_ that encapsulates a `Hash` is written as a value into
another `Map` _(A)_, and the value is read from the `Hash` encapsulated by
`Map` _A_, the result is the `Hash` that is encapsulated by `Map` _B_.  We say
that the value was "internalized" during storage.  A `List` is similarly
internalized as the `Array` that it encapsulates.

When a `Hash` _(B)_ is the value of an entry in another `Hash` _(A)_, and the
value is read from a `Map` that encapsulates `Hash` _A_, the result is a new
`Map` that encapsulates `Hash` _B_.  We say that the value was "externalized"
during retrieval.  An `Array` value is similarly externalized as a `List` that
encapsulates the underlying `Array`.

Values are also internalized during storage as items in a `List` and
externalized during retrieval from `List` items.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'map_with_indifferent_access'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install map_with_indifferent_access

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake rspec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment. Run `bundle exec
map_with_indifferent_access` to use the gem in this directory, ignoring other
installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/map_with_indifferent_access. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor Covenant](contributor-covenant.org) code
of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

