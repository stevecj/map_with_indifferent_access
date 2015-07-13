require 'spec_helper'

describe MapWithIndifferentAccess do
  subject{ described_class.new( inner_map ) }
  let( :inner_map ) { {} }

  it 'has a version number' do
    expect(MapWithIndifferentAccess::VERSION).not_to be nil
  end

  it "can be constructed as a wrapper around an existing hash" do
    hash = {}
    map = described_class.new( hash )
    expect( map.inner_map ).to equal( hash )
  end

  it "can be constructed as a wrapper asound an implicitly-created hash" do
    map = described_class.new
    expect( map.inner_map ).to be_kind_of( Hash )
  end

  it "can be constructed as a new wrapper around an existing wrapped hash" do
    hash = {}
    original_map = described_class.new( hash )
    map = described_class.new( original_map )
    expect( map ).not_to equal( original_map )
    expect( map.inner_map ).to equal( hash )
  end

  it "cannot be constructed with an un-hash-like argument to ::new" do
    expect{
      described_class.new( 1 )
    }.to raise_exception( ArgumentError )
  end

  it "cannot be converted from an un-hash-like object" do
    expect( described_class::try_convert( nil ) ).to be_nil
    expect( described_class::try_convert( 1   ) ).to be_nil
    expect( described_class::try_convert( []  ) ).to be_nil
  end

  it "can be converted from an instance of its class, returning the given map" do
    map = described_class::try_convert( subject )
    expect( map ).to equal( subject )
  end

  it "can be converted from a hash, wrapping the given hash" do
    hash = {}

    map = described_class::try_convert( hash )

    expect( map ).to be_kind_of( described_class)
    expect( map.inner_map ).to equal( hash )
  end

  describe '::[]' do
    it "returns the given object when not an Array, Hash, instance of self, or instance of self::Array" do
      expect( described_class[  nil  ] ).to eq(  nil )
      expect( described_class[ 'abc' ] ).to eq( 'abc' )
      expect( described_class[  123  ] ).to eq(  123 )

      timeval = Time.new(2010,11,16, 10,45,59)
      expect( described_class[ timeval ] ).to eq( timeval )
    end

    it "returns a wrapped instance of the given Hash" do
      given_hash = {a: 1}
      result = described_class[ given_hash ]
      expect( result.inner_map ).to equal( given_hash )
    end

    it "returns a wrapped instance of the given Array" do
      given_array = [ 1, 2, 3 ]
      result = described_class[ given_array ]
      expect( result.inner_array ).to equal( given_array )
    end

    it "returns the given instance of MapWithIndifferentAccess" do
      result = described_class[ subject ]
      expect( result ).to equal( subject )
    end

    it "returns the given instance of MapWithIndifferentAccess::Array" do
      given_array_wrapper = described_class::Array.new
      result = described_class[ given_array_wrapper ]
      expect( result ).to equal( given_array_wrapper )
    end
  end

  it "allows indexed read/write access to values" do
    subject[  1  ] = 'one'
    subject[ 'a' ] = 'A'
    subject[ :b  ] = 'B'
    expect( subject[  1  ] ).to eq( 'one' )
    expect( subject[ 'a' ] ).to eq( 'A'   )
    expect( subject[ :b  ] ).to eq( 'B'   )
  end

  it "treats string and symbol keys interchangeably" do
    subject[ 'a' ] = 'A'
    subject[ :b  ] = 'B'
    expect( subject[ :a  ] ).to eq( 'A' )
    expect( subject[ 'b' ] ).to eq( 'B' )
  end

  it "provides Hash-like #fetch behavior with key symbol/string indifference" do
    subject[  1  ] = 'one'
    subject[ 'a' ] = 'A'
    subject[ :b  ] = 'B'
    expect( subject.fetch(  1  ) ).to eq( 'one' )
    expect( subject.fetch( :a  ) ).to eq( 'A'   )
    expect( subject.fetch( 'b' ) ).to eq( 'B'   )

    expect{ subject.fetch('x') }.to raise_exception( KeyError )
    expect( subject.fetch('x') { '-' } ).to eq( '-' )
    expect( subject.fetch('x', '#') ).to eq( '#' )
  end

  it "provides its length/size" do
    subject[  1  ] = 'one'
    subject[ 'a' ] = 'A'
    expect( subject.length ).to eq( 2 )
    expect( subject.size   ).to eq( 2 )
  end

  it "enumerates keys in order added" do
    subject[  1     ] = 1
    subject[ 'two'  ] = 2
    subject[ :three ] = 3

    keys = []
    subject.each_key do |key| ; keys << key ; end
    expect( keys ).to eq( [1, 'two', :three] )
  end

  it "has unequal instances via #== with key-symbol-string-indifferently unequal entry sets" do
    subject[  1     ] = 1
    subject[ 'two'  ] = [ {a: 4} ]
    subject[ :three ] = 3

    other = described_class.new
    other[ 'three' ] = 3
    other[ :two    ] = [ {a: :fore} ]
    other[  1      ] = 1

    expect( subject == other ).to eq( false )
  end

  it "has equal instances via #== with key-symbol-string-indifferently equal entry sets" do
    subject[  1     ] = 1
    subject[ 'two'  ] = [ {a: 4} ]
    subject[ :three ] = 3

    other = described_class.new
    other[ 'three' ] = 3
    other[ :two    ] = [ {'a' => 4} ]
    other[  1      ] = 1

    expect( subject == other ).to eq( true )
  end

  describe '#each' do
    before do
      subject[  1     ] = 1
      subject[ 'two'  ] = { a: 1 }
      subject[ :three ] = [ 9 ]
    end

    it "is enumerates over key/value pairs when given a block" do
      entries = []
      subject.each do |entry| ; entries << entry ; end

      expect( entries.length ).to eq( 3 )

      expect( entries[0] ).to eq( [1, 1] )

      expect( entries[1][0] ).to eq( 'two' )
      expect( entries[1][1].inner_map ).to eq( {a: 1} )

      expect( entries[2][0] ).to eq( :three )
      expect( entries[2][1].inner_array ).to eq( [9] )

      expect( subject.entries ).to eq( entries )
    end

    it "returns an enumerator for key/value pairs when not given a block" do
      enum = subject.each

      expect( enum.next ).to eq( [1, 1] )

      enum.next.tap do |entry|
        expect( entry[0] ).to eq( 'two' )
        expect( entry[1].inner_map ).to eq( {a: 1} )
      end

      enum.next.tap do |entry|
        expect( entry[0] ).to eq( :three )
        expect( entry[1].inner_array ).to eq( [9] )
      end

      expect{ enum.next }.to raise_exception( StopIteration )
    end
  end

  describe '#each_key' do
    before do
      subject[  1     ] = 1
      subject[ 'two'  ] = { a: 1 }
      subject[ :three ] = [ 9 ]
    end

    it "provides enumeration of its keys in same order as added when given a block" do
      keys = []
      subject.each_key do |key| ; keys << key ; end
      expect( keys ).to eq(
        [1, 'two', :three]
      )
    end

    it "returns an enumerator over its keys in same order as added when not given a block" do
      enum = subject.each_key
      expect( enum.next ).to eq(  1     )
      expect( enum.next ).to eq( 'two'  )
      expect( enum.next ).to eq( :three )
    end
  end

  describe '#each_value' do
    before do
      subject[  1     ] = 1
      subject[ 'two'  ] = { a: 1 }
      subject[ :three ] = [ 9 ]
    end

    it "provides enumeration of its values in same order as added when given a block" do
      values = []
      subject.each_value do |value| ; values << value ; end
      expect( values.length ).to eq( 3 )
      expect( values[0] ).to eq( 1 )
      expect( values[1].inner_map ).to eq( { a: 1 } )
      expect( values[2].inner_array ).to eq( [9] )
    end

    it "provides an enumerator over its values in same order as added when not given a block" do
      enum = subject.each_value

      expect( enum.next ).to eq( 1 )
      expect( enum.next.inner_map ).to eq( { a: 1 } )
      expect( enum.next.inner_array ).to eq( [9] )
      expect{ enum.next }.to raise_exception( StopIteration )
    end
  end

  it "reflects later changes made to its inner hash map" do
    inner_map[ :foo ] = 123
    expect( subject['foo'] ).to eq( 123 )
  end

  it "reflects later changes back to its inner hash map" do
    subject[ :abc ] = 'ABC'
    expect( inner_map[:abc] ).to eq('ABC')
  end

  it "reflects hash-type values from its inner hash map as wrapped" do
    h = {}
    inner_map[:aaa] = h
    expect( subject[:aaa] ).to be_kind_of( described_class )
    expect( subject[:aaa].inner_map ).to equal( h )
  end

  it "reflects array-type values from its inner hash map as wrapped" do
    ary = []
    inner_map[:bbb] = ary
    expect( subject[:bbb] ).to be_kind_of( described_class::Array )
    expect( subject[:bbb].inner_array ).to equal( ary )
  end

  it "modifies the existing entry in its inner hash map with string/symbol indifference" do
    inner_map[ :aaa  ] = 'A'
    inner_map[ 'bbb' ] = 'B'
    subject[ 'aaa' ] = 'AA'
    subject[ :bbb  ] = 'BB'

    expect( inner_map ).to eq( {
      :aaa  => 'AA',
      'bbb' => 'BB'
    } )
  end

  describe '#delete' do
    let( :inner_map ) { Hash.new(:the_default) }

    describe "called without a block argument" do
      it "deletes the entry and returns the value for a string/symbolically indifferent map key" do
        inner_map[ :aaa  ] = { a: 1 }
        inner_map[ 'bbb' ] = 'B'

        result = subject.delete( 'aaa' )
        expect( inner_map ).to eq( {'bbb' => 'B'} )
        expect( result.inner_map ).to eq( {a: 1} )
      end

      it "deletes nothing and returns the \"default\" value for string/symbolically indifferent key mismatch" do
        # Experimentally found that in Ruby 1.9.3-p545 and who knows
        # what other versions,  Hash#delete always returns nil for a
        # mismatched key and not the default value as documented.
        # Here, we get the "default" value as returned by Hash#delete
        # for thecurrent Ruby, so we can assert that we get that.
        default_value = inner_map.delete( 'xxx' )

        inner_map[ :aaa  ] = { a: 1 }
        inner_map[ 'bbb' ] = 'B'

        result = subject.delete( 'xxx' )
        expect( inner_map ).to eq( {aaa: {a: 1}, 'bbb' => 'B'} )
        expect( result ).to eq( default_value )
      end
    end

    context "called with a block argument" do
      it "deletes the entry and returns the value for a string/symbolically indifferent map key" do
        inner_map[ :aaa  ] = { a: 1 }
        inner_map[ 'bbb' ] = 'B'

        result = subject.delete( 'aaa' ) { |key| "Nothing for #{key}" }
        expect( inner_map ).to eq( {'bbb' => 'B'} )
        expect( result.inner_map ).to eq( {a: 1} )
      end

      it "deletes nothing and returns the value from calling the block for string/symbolically indifferent key mismatch" do
        inner_map[ :aaa  ] = { a: 1 }
        inner_map[ 'bbb' ] = 'B'

        result = subject.delete( 'xxx' ) { |key| "Nothing for #{key.inspect}" }
        expect( inner_map ).to eq( {aaa: {a: 1}, 'bbb' => 'B'} )
        expect( result ).to eq( 'Nothing for "xxx"' )
      end
    end
  end

  describe '#assoc' do
    it "returns nil for am object that does not key/symbol indifferently == any map key" do
      subject[ :aaa  ] = 'A'
      subject[ 'bbb' ] = [ 'b' ]
      expect( subject.assoc( :x ) ).to be_nil
    end

    it "finds mathcing key/value entry by == for a non-string-or-symbol object" do
      subject[ :aaa  ] = 'A'
      subject[  10   ] = [ 'b' ]

      key, value = subject.assoc( 10.0 )

      expect( key ).to eql( 10 )
      expect( value ).to eq(
        described_class::Array.new( [ 'b' ] )
      )
    end

    it "finds matching key/value entry for key with string/symbol indifference" do
      subject[ :aaa  ] = 'A'
      subject[ :bbb  ] = [ 'b' ]

      key, value = subject.assoc( 'bbb' )

      expect( key ).to eql( :bbb )
      expect( value ).to eq(
        described_class::Array.new( [ 'b' ] )
      )
    end

    it "removes all entries from inner hash map using #clear" do
      inner_map[:a] = 1
      inner_map[:b] = 2

      subject.clear

      expect( inner_map ).to be_empty
    end

  end

end
