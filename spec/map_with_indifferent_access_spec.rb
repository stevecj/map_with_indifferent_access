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

  it "deconstructs a map instance to its inner hash map" do
    result = described_class.try_deconstruct( subject )
    expect( result ).to equal( subject.inner_map )
  end

  it "deconstructs a hash instance to itself" do
    hash = {}
    result = described_class.try_deconstruct( hash )
    expect( result ).to equal( hash )
  end

  it "deconstructs objects that are not map or Hash type as `nil`" do
    expect( described_class.try_deconstruct( 10   ) ).to eq( nil )
    expect( described_class.try_deconstruct( true ) ).to eq( nil )
    expect( described_class.try_deconstruct('xy'  ) ).to eq( nil )
    expect( described_class.try_deconstruct( []   ) ).to eq( nil )
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

  describe '::valueize / ::<<' do
    it "returns the given object when not an Array, Hash, instance of self, or instance of self::Array" do
      expect( described_class <<  nil  ).to eq( nil )
      expect( described_class << 'abc' ).to eq('abc')
      expect( described_class <<  123  ).to eq( 123 )

      timeval = Time.new( 2010,11,16, 10,45,59 )
      expect( described_class << timeval ).to eq( timeval )
    end

    it "returns a wrapped instance of the given Hash" do
      given_hash = { a: 1 }
      result = described_class << given_hash
      expect( result.inner_map ).to equal( given_hash )
    end

    it "returns a wrapped instance of the given Array" do
      given_array = [ 1, 2, 3 ]
      result = described_class << given_array
      expect( result.inner_array ).to equal( given_array )
    end

    it "returns the given instance of MapWithIndifferentAccess" do
      result = described_class << subject
      expect( result ).to equal( subject )
    end

    it "returns the given instance of MapWithIndifferentAccess::Array" do
      given_array_wrapper = described_class::Array.new
      result = described_class << given_array_wrapper
      expect( result ).to equal( given_array_wrapper )
    end
  end

  describe '::unvalueize / ::>>' do
    it "returns the given object when not a wrapped-hash map or wrapped array" do
      expect( described_class >>  nil  ).to eq(  nil  )
      expect( described_class >> 'abc' ).to eq( 'abc' )
      expect( described_class >>  123  ).to eq(  123  )
      expect( described_class >> [ 9 ] ).to eq( [ 9 ] )
    end

    it "returns the inner hash map from a given wrapped wrapped hash map" do
      expect( described_class >> subject  ).to equal( subject.inner_map )
    end

    it "returns the inner array from a given wrapped wrapped array" do
      wrapped_array = described_class::Array.new
      expect( described_class >> wrapped_array ).to equal( wrapped_array.inner_array )
    end
  end

  describe '#internalize_key' do
    before do
      inner_map[ 1 ] = 'one'
      inner_map['a'] = 'A'
      inner_map[:b ] = 'B'
    end

    it "returns the given value not matching any existing key" do
      expect( subject.internalize_key( 2 ) ).to eq( 2 )
      expect( subject.internalize_key('c') ).to eq('c')
      expect( subject.internalize_key(:d ) ).to eq(:d )
    end

    it "returns the given value equal to an existing key" do
      expect( subject.internalize_key( 1 ) ).to eq( 1 )
      expect( subject.internalize_key('a') ).to eq('a')
      expect( subject.internalize_key(:b ) ).to eq(:b )
    end

    it "returns the existing String-type key matching a given Symbol-type value" do
      expect( subject.internalize_key(:a ) ).to eq('a')
    end

    it "returns the existing Symbol-type key matching a given string-type value" do
      expect( subject.internalize_key('b') ).to eq(:b )
    end
  end

  describe "indexed value access" do
    it "creates a new entry for an external key with no internalized match" do
      subject['a'] = 'A'
      subject[:b ] = 'B'
      expect( inner_map ).to eq( {
        'a' => 'A',
        :b  => 'B'
      } )
    end

    it "updates the value of an existing entry by external key with internalized match" do
      subject['v'] = 'V'
      subject[:v ] = 'Vee'
      expect( inner_map ).to eq( {'v' => 'Vee'} )
    end

    it "unvalueizes the given value when storing" do
      subject[ 1 ] = described_class.new( a: 5 )
      expect( inner_map ).to eq( {
        1 => { a: 5 }
      } )
    end

    it "retrieves the inner-map hash's default value for an external key with no internalized match" do
      inner_map.default_proc = ->(h,k) { "~#{k}~" }
      expect( subject['xyz'] ).to eq('~xyz~')
    end

    it "retrieves the value of the matching entry from the inner-map has by internalized key" do
      inner_map['a'] = 5
      expect( subject[:a ] ).to eq( 5 )
    end

    it "valueizes the stored value when retrieving" do
      inner_map[ 1 ] = { 'a' => 9 }
      expect( subject[ 1 ].inner_map ).to eq( {'a' => 9 } )
    end
  end

  describe '#fetch' do
    before do
      inner_map[ 1 ] = 'one'
      inner_map['a'] = 'A'
      inner_map[:b ] = 'B'
      inner_map[:x ] =  {}
      inner_map[:y ] =  []
    end

    it "retrieves the value of the matching entry from the inner-map hash by internalized key" do
      inner_map['a'] = 5
      expect( subject.fetch(:a ) ).to eq( 5 )
    end

    it "valueizes the stored value when retrieving" do
      inner_map[ 1 ] = {'a' => 9 }
      expect( subject.fetch( 1 ).inner_map ).to eq( {'a' => 9 } )
    end

    it "raises a KeyError exception for an internalized-key mismatch and no fallback" do
      expect{ subject.fetch('q') }.to raise_exception( KeyError )
    end

    it "returns the given default value for an internalized-key mismatch" do
      expect( subject.fetch('q', '#') ).to eq('#')
    end

    it "returns the block-call result for an internalized-key mismatch" do
      expect( subject.fetch('q') {|key| key.inspect } ).to eq('"q"')
    end
  end

  describe '#delete' do
    let(:inner_map ) { Hash.new(:the_default ) }

    describe "called without a block argument" do
      it "deletes the entry and returns the value for the inernalization of an external key" do
        inner_map[ :aaa  ] = { a: 1 }
        inner_map[ 'bbb' ] = 'B'

        result = subject.delete( 'aaa' )
        expect( inner_map ).to eq( {'bbb' => 'B'} )
        expect( result.inner_map ).to eq( { a: 1 } )
      end

      it "deletes nothing and returns the \"default\" value for an internalized-key mismatch" do
        # Experimentally found that in Ruby 1.9.3-p545 and who knows
        # what other versions,  Hash#delete always returns nil for a
        # mismatched key and not the default value as per the Ruby
        # documentation.
        # Here, we get the "default" value as returned by Hash#delete
        # for the current Ruby, so we can assert getting the same
        # value.
        default_value = inner_map.delete('xxx')

        inner_map[:aaa ] = { a: 1 }
        inner_map['bbb'] = 'B'

        result = subject.delete('xxx')
        expect( inner_map ).to eq( { aaa: { a: 1 }, 'bbb' => 'B'} )
        expect( result ).to eq( default_value )
      end
    end

    describe '#key' do
      before do
        inner_map[ 1 ] = 1
        inner_map[:b ] = {:bb  => 'B'}
        inner_map['c'] = [ {'cc' => 'C'} ]
        inner_map[:d ] = 'D'
      end

      it "returns nil for a value dissimilar to any value in the map" do
        result = subject.key( 2 )
        expect( result ).to eq( nil )
      end

      it "returns the key for an arbitrary type of value in the map" do
        result = subject.key('D')
        expect( result ).to eq(:d )
      end

      it "returns the key for an entry vith valuized-value equal to valuization of the given value" do
        hash = {'bb' => 'B'}
        map = described_class.new( hash )
        expect( subject.key( hash ) ).to eq(:b )
        expect( subject.key( map  ) ).to eq(:b )
      end
    end

    describe "conditional deletion/keeping of entries" do
      before do
        inner_map['a'] = 'AAA'
        inner_map[:b ] =  {}
        inner_map[:c ] =  []
        inner_map[:d ] =  4
      end

      describe '#delete_if' do
        it "passes the key and valuized-value of each entry the given block and those for which the block returns true" do
          subject.delete_if { |key,value|
            String === key ||
            value.respond_to?(:inner_map   ) ||
            value.respond_to?(:inner_array )
          }

          expect( inner_map ).to eq( { d: 4 } )
        end

        it "with no block given, returns an enumerator over key, valuized-value pairs from entries and delted those for which true is fed to the enumerator" do
          enum = subject.delete_if

          expect( enum.next ).to eq( ['a', 'AAA'] )

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:b )
            expect( value.inner_map ).to eq( {} )
          end
          enum.feed true

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:c )
            expect( value.inner_array ).to eq( [] )
          end
          enum.feed true

          expect( enum.next ).to eq( [:d, 4 ] )
          enum.feed false

          expect( inner_map ).to eq( {
            'a' => 'AAA',
            :d  =>  4
          } )
        end
      end

      describe '#keep_if' do
        it "passes each key/value to the given block and deletes entries for which the block returns true" do
          subject.keep_if { |key,value|
            String === key ||
            Numeric === value ||
            Hash === value ||
            Array === value
          }

          expect( inner_map ).to eq( {
            'a' => 'AAA',
            :d  =>  4
          } )
        end

        it "with no block given, returns an enumerator over key, valuized-value pairs from entries and delted those for which false is fed to the enumerator" do
          enum = subject.keep_if

          expect( enum.next ).to eq( ['a', 'AAA'] )
          enum.feed true

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:b )
            expect( value.inner_map ).to eq( {} )
          end

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:c )
            expect( value.inner_array ).to eq( [] )
          end

          expect( enum.next ).to eq( [:d, 4 ] )
          enum.feed true

          expect( inner_map ).to eq( {
            'a' => 'AAA',
            :d  =>  4
          } )
        end
      end
    end
  end

  it "removes all entries from inner hash map using #clear" do
    inner_map[:a ] = 1
    inner_map[:b ] = 2

    subject.clear

    expect( inner_map ).to be_empty
  end

  it "provides its length/size" do
    subject[ 1 ] = 'one'
    subject['a'] = 'A'
    expect( subject.length ).to eq( 2 )
    expect( subject.size   ).to eq( 2 )
  end

  it "indicates whether the internalization of a given key is present in the inner-map hash" do
    subject[ 1 ] = 'one'
    subject['a'] = 'A'

    expect( subject.key?( 2 ) ).to eq( false )
    expect( subject.key?('c') ).to eq( false )
    expect( subject.key?( 1 ) ).to eq( true  )
    expect( subject.key?(:a ) ).to eq( true  )
  end

  it "enumerates keys in order added" do
    subject[ 1     ] = 1
    subject['two'  ] = 2
    subject[:three ] = 3

    keys = []
    subject.each_key do |key| ; keys << key ; end
    expect( keys ).to eq( [ 1, 'two', :three ] )
  end

  it "#default returns the default value for the case where the internalization of the given key does not match an entry" do
    inner_map.default_proc = ->(hash, key) { key ? "#{key.inspect} in #{hash.inspect}" : [ key, hash ] }
    expect( subject.default(:a )         ).to eq(":a in {}")
    expect( subject.default.inner_array ).to eq( [ nil, {} ]  )
  end

  describe '#==' do
    let(:inner_map ) { {
      :a  => 1,
      'b' => 2,
      'c' => {:cc => 33, 'ccc' => 333 },
      :d  => [ 4, {'dd' => 44, :ddd => 444 } ]
    } }
    let( :similar_hash ) { {
      'a' => 1,
      :b  => 2,
      :c  => {:cc => 33, :ccc => 333 },
      'd' => [ 4, {'dd' => 44, 'ddd' => 444 } ]
    } }
    let( :dissimilar_hash ) { {
      :a  => 1,
      'b' => 2,
      'c' => {:cc => 33, 'ccc' => 999 }, # Only distinction -- 999 vs 333
      :d  => [ 4, {'dd' => 44, :ddd => 444 } ]
    } }

    it "returns false given a map that is different w/ key string/symbolic indifference" do
      map = described_class.new( dissimilar_hash )
      expect( subject == map ).to eq( false )
    end

    it "returns false given a Hash that is different w/ key string/symbolic indifference" do
      expect( subject == dissimilar_hash ).to eq( false )
    end

    it "returns true given a map that is the same w/ key string/symbolic indifference" do
      map = described_class.new( similar_hash )
      expect( subject == map ).to eq( true )
    end

    it "returns true given a Hash that is the same w/ key string/symbolic indifference" do
      expect( subject == similar_hash ).to eq( true )
    end
  end

  describe '#each' do
    before do
      subject[ 1     ] = 1
      subject['two'  ] = { a: 1 }
      subject[:three ] = [ 9 ]
    end

    it "given a block, enumerates key, valuized-value pairs for entries" do
      entries = []

      subject.each do |entry| ; entries << entry ; end

      expect( entries.length ).to eq( 3 )

      expect( entries[ 0 ] ).to eq( [ 1, 1 ] )

      expect( entries[ 1 ][ 0 ] ).to eq('two')
      expect( entries[ 1 ][ 1 ].inner_map ).to eq( { a: 1 } )

      expect( entries[ 2 ][ 0 ] ).to eq(:three )
      expect( entries[ 2 ][ 1 ].inner_array ).to eq( [ 9 ] )

      expect( subject.entries ).to eq( entries )
    end

    it "without a block argument, returns an enumerator over key, valuized-value pairs for entries" do
      enum = subject.each

      expect( enum.next ).to eq( [ 1, 1 ] )

      enum.next.tap do |entry|
        expect( entry[ 0 ] ).to eq('two')
        expect( entry[ 1 ].inner_map ).to eq( { a: 1 } )
      end

      enum.next.tap do |entry|
        expect( entry[ 0 ] ).to eq(:three )
        expect( entry[ 1 ].inner_array ).to eq( [ 9 ] )
      end

      expect{ enum.next }.to raise_exception( StopIteration )
    end
  end

  describe '#each_key' do
    before do
      subject[ 1     ] = 1
      subject['two'  ] = { a: 1 }
      subject[:three ] = [ 9 ]
    end

    it "given a block argument, provides enumeration of its keys in same order as added" do
      keys = []
      subject.each_key do |key| ; keys << key ; end
      expect( keys ).to eq(
        [ 1, 'two', :three ]
      )
    end

    it "without a block argument, returns an enumerator over its keys in same order as added" do
      enum = subject.each_key

      expect( enum.next ).to eq( 1     )
      expect( enum.next ).to eq('two'  )
      expect( enum.next ).to eq(:three )
      expect{ enum.next }.to raise_exception( StopIteration )
    end
  end

  describe '#each_value' do
    before do
      subject[ 1     ] = 1
      subject['two'  ] = { a: 1 }
      subject[:three ] = [ 9 ]
    end

    it "provides enumeration of its appropriately-wrapped values in same order as added when given a block" do
      values = []

      subject.each_value do |value| ; values << value ; end

      expect( values.length ).to eq( 3 )
      expect( values[ 0 ] ).to eq( 1 )
      expect( values[ 1 ].inner_map ).to eq( { a: 1 } )
      expect( values[ 2 ].inner_array ).to eq( [ 9 ] )
    end

    it "provides an enumerator over its appropriately-wrapped values in same order as added when not given a block" do
      enum = subject.each_value

      expect( enum.next ).to eq( 1 )
      expect( enum.next.inner_map ).to eq( { a: 1 } )
      expect( enum.next.inner_array ).to eq( [ 9 ] )
      expect{ enum.next }.to raise_exception( StopIteration )
    end
  end

  describe '#assoc' do
    it "returns nil for a key value, the internalization of which != any key in the inner-map hash" do
      subject[:aaa ] = 'A'
      subject['bbb'] = ['b']
      expect( subject.assoc(:x ) ).to be_nil
    end

    it "given the key,valuized-value for a matching entry, given a key, the inernalization of which is == to the key of the entry" do
      subject[:aaa ] = 'A'
      subject[ 10  ] = ['b']

      key, value = subject.assoc( 10.0 )

      expect( key ).to eql( 10 )
      expect( value.inner_array ).to eq( ['b'] )
    end

    it "finds matching key/value entry for the internalization of the given key" do
      subject[:aaa ] = 'A'
      subject[:bbb ] = ['b']

      key, value = subject.assoc('bbb')

      expect( key ).to eql(:bbb )
      expect( value ).to eq(
        described_class::Array.new( ['b'] )
      )
    end
  end

  describe '#rassoc' do
    before do
      inner_map[ 1 ] = 1
      inner_map[:b ] = {:bb  => 'B'}
    end

    it "returns nil for a value, the valuization of which is != the valuization of any value in the inner-map hash" do
      result = subject.rassoc( 2 )
      expect( result ).to eq( nil )
    end

    it "returns the key, valuized-value pair for an entry with valuized-value == the valuization of the given value" do
      map = described_class.new( {'bb' => 'B'} )

      result = subject.rassoc( map )
      expect( result.first ).to eq(:b )
      expect( result.last.inner_map ).to eq( {:bb => 'B'} )
    end
  end

  describe '#has_value?' do
    before do
      inner_map[ 1 ] = 1
      inner_map[:b ] = {:bb  => 'B'}
    end

    it "returns false for a value, the valuization of which is != the valuization of any value in the inner-map hash" do
      expect( subject.has_value?( 2 ) ).to eq( false )
    end

    it "returns true for a value, the valuization of which is == the valuization of any value in the inner-map hash" do
      map = described_class.new( {'bb' => 'B'} )
      expect( subject.has_value?( map ) ).to eq( true )
    end
  end

  describe 'map-merging' do
    before do
      inner_map[ 1 ] =  11
      inner_map['a'] = 'AA'
      inner_map['b'] = 'BB'
      inner_map[:c ] = 'CC'
      inner_map[:d ] = 'DD'
    end

    context "given an argument with keys, the target-internalizations of which do not match keys in the inner-map hash" do
      let( :hash ) { {
         2  =>  222,
        'e' => 'EEE',
        :f  => 'FFF'
      } }
      let( :expected_inner_map ) { {
         1 => 11,  'a' => 'AA',  'b' => 'BB', :c => 'CC', :d => 'DD',
         2 => 222, 'e' => 'EEE', :f  => 'FFF'
      } }

      describe '#merge' do
        it "returns a new map with entries from the target map and the given hash" do
          result = subject.merge( hash )
          expect( result.inner_map ).to eq( expected_inner_map )
        end

        it "returns a new map with entries from the target map and the inner hash-map of the given map" do
          map = described_class.new( hash )
          result = subject.merge( map )
          expect( result.inner_map ).to eq( expected_inner_map )
        end
      end

      describe '#!merge' do
        it "adds entries from the given hash into itself" do
          subject.merge! hash
          expect( subject.inner_map ).to eq( expected_inner_map )
        end

        it "adds entries from the inner hash-map of the given hash into itself" do
          map = described_class.new( hash )
          subject.merge! map
          expect( subject.inner_map ).to eq( expected_inner_map )
        end
      end
    end

    context "given an argument with keys, the target-internalizations of which match keys in the inner-map hash" do
      let( :hash ) { {
         1  =>  111,
        'a' => 'AAA', :b  => 'BBB',
        'c' => 'CCC', :d  => 'DDD'
      } }
      let( :expected_inner_map ) { {
          1 => 111,
         'a' => 'AAA', 'b' => 'BBB',
         :c  => 'CCC', :d  => 'DDD'
      } }

      describe '#merge' do
        it "returns a new map with entries from the map and values from the given hash" do
          result = subject.merge( hash )
          expect( result.inner_map ).to eq( expected_inner_map )
        end

        it "returns a new map with entries from the map and values from the inner hash-map of the given map" do
          map = described_class.new( hash )
          result = subject.merge( map )
          expect( result.inner_map ).to eq( expected_inner_map )
        end
      end

      describe '#merge!' do
        it "replaces values of its entries with those from the matches in the given hash into itself" do
          subject.merge! hash
          expect( subject.inner_map ).to eq( expected_inner_map )
        end

        it "replaces values of its entries with those from the matches in the inner-map hash of the given map into itself" do
          map = described_class.new( hash )
          subject.merge! map
          expect( subject.inner_map ).to eq( expected_inner_map )
        end
      end
    end
  end

end
