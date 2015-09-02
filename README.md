# MapWithIndifferentAccess

A wrapper around Hash that treats String and Symbol keys as interchangeable.

Note that this gem is still in early development stages and does not yet have
any released versions.

Provides a `HashWithIndifferentAccess::Map` class that acts as a wrapper
around a `Hash` and provides `String`/`Symbol` indifferent access to its
entries.

## Comparison to ActiveSupport's HashWithIndifferentAccess

Behaves similarly to `HashWithIndifferentAccess` from ActiveSupport, but with
the following differences.

As of this writing, in order to have `HashWithIndifferentAccess` work as
expected, it is necessary to load pretty much all of ActiveSupport, which
modifies the behavior of other classes in ways that you might or might not
want.

`MapWithIndifferentAccess` does not currently alter any of the standard Ruby
classes, but might make some very careful changes to those in future versions.

When a Hash-type object is added as a value into a
`HashWithIndifferentAccess`, it is copied into a new
`HashWithIndifferentAccess` that is entirely independent of the provided
`Hash`.

When reading a `Hash` from a `MapWithIndifferentAccess::Map`, on the other
hand, it is wrapped in a `MapWithIndifferentAccess::Map` that remains
coupled to the originally provided `Hash` instance.

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

When a `Hash` is added to an `Array` that is the value of an entry in a
`HashWithIndifferentAccess`, that `Hash` is automatically copied into a
`HashWithIndifferentAccess` that is independent of the original `Hash`.

When reading an array from a value in a `MapWithIndifferentAccess::Map`, it is
wrapped in a `MapWithIndifferentAccess::Array` which returns wrapped items for
any `Array` or `Hash` items that are read from it.


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

