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

code:

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
When an `Array` containing one or more `Hash` items is stored as a value in
a `HashWithIndifferentAccess`, the `Hash` items in the array are replaced
with new `HashWithIndifferentAccess` copies that are independent of the
original hashes.

code:

    a = [ foo = {} ]
    h = HashWithIndifferentAccess.new
    h[:a] = a
    foo[:bar] = 'BAR'
    puts h[:a].first[:bar].inspect

Output:

    nil

When an `Array` containing one or more `Hash` items is stored as a value in
a `MapWithIndifferentAccess::Map`, the given array is placed directly into
the underlying wrapped hash.  The `Array` is wrapped in a
`MapWithIndifferentAccess::List` during subsequent retrieval, and the hash
item that it contains is wrapped in another `MapWithIndifferentAccess::Map`
on retrieval from the list.

code:

    a = [ foo = {} ]
    h = MapWithIndifferentAccess.new
    h[:a] = a
    foo[:bar] = 'BAR'
    puts h[:a].first[:bar].inspect

Output:

    "BAR"


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
nested structure of `Map`s and `List`s.  Assigning a `Map` or `List` as a
value or item in other `Map` or `List` results in a corresponding `Hash` or
`Array` being placed into the encapsulated (`Hash` or `Array`) collection.
Retrieving an entry value or item that is internally stored as a `Hash` or
`Array` from a `Map` or `List` results in a `Map` or `List` that encapsulates
the underlying entry/item value.

Converting a value from a `Map` to a `Hash` or from a `List` to an `Array`
during storage into an encapsulated collection is known as "internalization".

Converting a value from a `Hash` to a `Map` or from an `Array` to a list
during retrieval from an encapsulated collection is known as
"externalization".


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

To build a new empty `MapWithIndifferentAccess::Map`, ...

    map = MapWithIndifferentAccess.new

... or ...

    map = MapWithIndifferentAccess::Map.new

To build a new `MapWithIndifferentAccess::Map` around an existing `Hash`, ...

    map = MapWithIndifferentAccess.new(some_existing_hash)

... or ...

    map = MapWithIndifferentAccess::Map.new(some_existing_hash)

To retrieve the encapsulated `Hash` from a `MapWithIndifferentAccess::Map`,
...

    hash = map.inner_map

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

