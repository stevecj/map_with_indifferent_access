require 'spec_helper'
require_relative 'wraps_collection_examples'

module MapWithIndifferentAccessSpec
  include MapWithIndifferentAccess::WithConveniences

  describe MWIA::Map do
    subject{ described_class.new( inner_map ) }
    let( :inner_map ) { {} }
    let( :inner_collection ) { inner_map }

    it 'has a version number' do
      expect(MWIA::VERSION).not_to be nil
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

    it "can be constructed as a new wrapper around ther inner-map hash of an existing wrapped hash" do
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
      expect( described_class.try_convert( nil ) ).to be_nil
      expect( described_class.try_convert( 1   ) ).to be_nil
      expect( described_class.try_convert( []  ) ).to be_nil
    end

    it "can be converted from an instance of its class, returning the given map" do
      map = described_class.try_convert( subject )
      expect( map ).to equal( subject )
    end

    it "can be converted from a hash, wrapping the given hash" do
      hash = {}

      map = described_class.try_convert( hash )

      expect( map ).to be_kind_of( described_class )
      expect( map.inner_map ).to equal( hash )
    end

    describe '#conform_key' do
      before do
        inner_map[ 1 ] = 'one'
        inner_map['a'] = 'A'
        inner_map[:b ] = 'B'
      end

      it "returns the given value not matching any existing key" do
        expect( subject.conform_key( 2 ) ).to eq( 2 )
        expect( subject.conform_key('c') ).to eq('c')
        expect( subject.conform_key(:d ) ).to eq(:d )
      end

      it "returns the given value equal to an existing key" do
        expect( subject.conform_key( 1 ) ).to eq( 1 )
        expect( subject.conform_key('a') ).to eq('a')
        expect( subject.conform_key(:b ) ).to eq(:b )
      end

      it "returns the existing String-type key matching a given Symbol-type value" do
        expect( subject.conform_key(:a ) ).to eq('a')
      end

      it "returns the existing Symbol-type key matching a given string-type value" do
        expect( subject.conform_key('b') ).to eq(:b )
      end
    end

    describe "indexed value access" do
      it "creates a new entry for an external key with no conformed match" do
        subject['a'] = 'A'
        subject[:b ] = 'B'
        expect( inner_map ).to eq( {
          'a' => 'A',
          :b  => 'B'
        } )
      end

      it "updates the value of an existing entry by external key with conformed match" do
        subject['v'] = 'V'
        subject[:v ] = 'Vee'
        expect( inner_map ).to eq( {'v' => 'Vee'} )
      end

      it "internalizes the given value when storing" do
        subject[ 1 ] = described_class.new( a: 5 )
        expect( inner_map ).to eq( {
          1 => { a: 5 }
        } )
      end

      it "retrieves the externalization of the inner-map hash's default value for an external key with no conformed match" do
        inner_map.default_proc = ->(h,k) { { key: k } }
        expect( subject['xyz'] ).to eq( described_class.new( key: 'xyz' ) )
      end

      it "retrieves the externalization of the value of the matching entry from the inner-map has by conformed key" do
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

      it "retrieves the externalization of the value of the matching entry from the inner-map hash by conformed key" do
        inner_map[ 1 ] = {'a' => 9 }
        expect( subject.fetch( 1 ).inner_map ).to eq( {'a' => 9 } )
      end

      it "raises a KeyError exception for a conformed-key mismatch and no fallback" do
        expect{ subject.fetch('q') }.to raise_exception( KeyError )
      end

      it "returns the externalization of the given default value for an conformed-key mismatch" do
        result = subject.fetch('q', { a: 1 } )
        expect( result.inner_map ).to eq( { a: 1 } )
      end

      it "returns the externalization of block-call result for a conformed-key mismatch" do
        result = subject.fetch('q') {|key| { key: key } }
        expect( result ).to eq( described_class.new( key: 'q' ) )
      end
    end

    it_behaves_like "a collection wrapper"

    describe '#dup' do
      context "with an unfrozen inner-map hash" do
        let(:inner_map ) { { abc: 123 } }

        it "returns a new map with an unfrozen duplicate of the original's unfrozen inner-map hash" do
          result = subject.dup
          expect( result ).not_to equal( subject )
          expect( result.inner_map ).to eq( inner_map )
          expect( result.inner_map ).not_to equal( inner_map )
          expect( result.inner_map ).not_to be_frozen
        end

        it "returns a new map with an unfrozen duplicate of the original's frozen inner-map hash" do
          inner_map.freeze

          result = subject.dup
          expect( result ).not_to equal( subject )
          expect( result.inner_map ).to eq( inner_map )
          expect( result.inner_map ).not_to equal( inner_map )
          expect( result.inner_map ).not_to be_frozen
        end
      end
    end

    describe '#clone' do
      context "with an unfrozen inner-map hash" do
        let(:inner_map ) { { abc: 123 } }

        it "returns a new map with an unfrozen duplicate of the original's unfrozen inner-map hash" do
          result = subject.clone
          expect( result ).not_to equal( subject )
          expect( result.inner_map ).to eq( inner_map )
          expect( result.inner_map ).not_to equal( inner_map )
          expect( result.inner_map ).not_to be_frozen
        end

        it "returns a new map with a frozen duplicate of the original's frozen inner-map hash" do
          inner_map.freeze

          result = subject.clone
          expect( result ).not_to equal( subject )
          expect( result.inner_map ).to eq( inner_map )
          expect( result.inner_map ).not_to equal( inner_map )
          expect( result.inner_map ).to be_frozen
        end
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

      it "returns the key for an entry vith externalized-value equal to externalization of the given value" do
        hash = {'bb' => 'B'}
        map = described_class.new( hash )
        expect( subject.key( hash ) ).to eq(:b )
        expect( subject.key( map  ) ).to eq(:b )
      end
    end

    describe '#delete' do
      let(:inner_map ) { Hash.new(:the_default ) }

      describe "called without a block argument" do
        it "deletes the entry and returns the value for the conformation of the given key" do
          inner_map[ :aaa  ] = { a: 1 }
          inner_map[ 'bbb' ] = 'B'

          result = subject.delete( 'aaa' )
          expect( inner_map ).to eq( {'bbb' => 'B'} )
          expect( result.inner_map ).to eq( { a: 1 } )
        end

        it "deletes nothing and returns the \"default\" value for an conformed-key mismatch" do
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

    it "indicates whether the conformation of a given key is present in the inner-map hash" do
      subject[ 1 ] = 'one'
      subject['a'] = 'A'

      expect( subject.key?( 2 ) ).to eq( false )
      expect( subject.key?('c') ).to eq( false )
      expect( subject.key?( 1 ) ).to eq( true  )
      expect( subject.key?(:a ) ).to eq( true  )
    end

    it "returns fron #default, the default value for the case where the conformation of the given key does not match an entry" do
      inner_map.default_proc = ->(hash, key) { key ? "#{key.inspect} in #{hash.inspect}" : [ key, hash ] }
      expect( subject.default(:a )        ).to eq(":a in {}")
      expect( subject.default.inner_array ).to eq( [ nil, {} ] )
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

    describe '#eql?' do
      it "returns false, given a non-Map object" do
        expect( subject.eql?( inner_map ) ).to eq( false )
      end

      it "returns false, given a Map with an inner-map hash not #eql? to its own" do
        other = subject.dup
        other['d'] = other.inner_map.delete(:d )
        expect( subject.eql?( other ) ).to eq( false )
      end

      it "returns true, given a Map with an inner-map that is #eql? to its own" do
        other = subject.dup
        expect( subject.eql?( other ) ).to eq( true )
      end
    end

    describe '#each' do
      before do
        subject[ 1     ] = 1
        subject['two'  ] = { a: 1 }
        subject[:three ] = [ 9 ]
      end

      context "given a block" do
        it "enumerates key, externalized-value pairs for entries" do
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

        it "returns the target map" do
          expect( subject.each{ 'foo' } ).to equal( subject )
        end
      end

      it "without a block argument, returns an enumerator over key, externalized-value pairs for entries" do
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

    describe "conditional deletion/retaining of entries" do
      before do
        inner_map['a'] = 'AAA'
        inner_map[:b ] =  {}
        inner_map[:c ] =  []
        inner_map[:d ] =  4
        inner_map[:e ] =  5
      end

      shared_examples "deletes/retains entries" do |subj_method, delete_on, retain_on|
        it "passes the key and externalized-value of each entry the given block and deletes those for which the block returns #{delete_on}" do
          subject.send(subj_method){ |key,value|
            delete_it = 
              String === key ||
              value.respond_to?(:inner_map   ) ||
              value.respond_to?(:inner_array ) ||
              key == :e
            delete_it ? delete_on : retain_on
          }

          expect( inner_map ).to eq( { d: 4 } )
        end

        it "with no block given, returns an enumerator over key, externalized-value pairs from entries and deletes those for which #{delete_on} is fed to the enumerator" do
          enum = subject.send(subj_method)

          expect( enum.next ).to eq( ['a', 'AAA'] )
          enum.feed retain_on

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:b )
            expect( value.inner_map ).to eq( {} )
          end
          enum.feed delete_on

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:c )
            expect( value.inner_array ).to eq( [] )
          end
          enum.feed delete_on

          expect( enum.next ).to eq( [:d, 4 ] )
          enum.feed retain_on

          expect( enum.next ).to eq( [:e, 5 ] )
          enum.feed delete_on

          expect{ enum.next }.to raise_exception( StopIteration )

          expect( inner_map ).to eq( {
            'a' => 'AAA',
            :d  =>  4
          } )
        end

        it "returns the target when a block is given that sometimes returns #{delete_on}" do
          result = subject.delete_if{ |key,value| value == 4 ? delete_on : retain_on  }
          expect( result ).to equal subject
        end
      end

      describe '#delete_if' do
        include_examples "deletes/retains entries", :delete_if, true, false

        it "returns the target when a block is given that never returns true" do
          result = subject.delete_if{ |*| false }
          expect( result ).to equal subject
        end

      end

      describe '#reject!' do
        include_examples "deletes/retains entries", :reject!, true, false

        it "returns nil when a block is given that never returns true" do
          result = subject.reject!{ |*| false }
          expect( result ).to be_nil
        end
      end

      describe '#keep_if' do
        include_examples "deletes/retains entries", :keep_if, false, true

        it "returns the target when a block is given that never returns false" do
          result = subject.keep_if{ |*| true }
          expect( result ).to equal subject
        end
      end

      describe '#select!' do
        include_examples "deletes/retains entries", :keep_if, false, true

        it "returns nil target when a block is given that never returns false" do
          result = subject.select!{ |*| true }
          expect( result ).to be_nil
        end
      end
    end

    describe "conditional selection/rejection of entries" do
      before do
        inner_map['a'] = 'AAA'
        inner_map[:b ] =  {}
        inner_map[:c ] =  []
        inner_map[:d ] =  4
        inner_map[:e ] =  5
      end

      shared_examples "selects/rejects entries" do |subj_method, select_on, reject_on|
        it "passes the key and externalized-value of each entry the given block and returns a new map containing those for which the block returns #{select_on}" do
          result = subject.send(subj_method){ |key,value|
            reject_it = 
              String === key ||
              value.respond_to?(:inner_map   ) ||
              value.respond_to?(:inner_array ) ||
              key == :e
            reject_it ? reject_on : select_on
          }

          expect( result.inner_map ).to eq( { d: 4 } )
        end

        it "with no block given, returns an enumerator over key, externalized-value pairs from entries and stops iteration with a new map containing those for which #{select_on} is fed to the enumerator" do
          enum = subject.send(subj_method)

          expect( enum.next ).to eq( ['a', 'AAA'] )
          enum.feed select_on

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:b )
            expect( value.inner_map ).to eq( {} )
          end
          enum.feed reject_on

          enum.next.tap do |(key,value)|
            expect( key ).to eq(:c )
            expect( value.inner_array ).to eq( [] )
          end
          enum.feed reject_on

          expect( enum.next ).to eq( [:d, 4 ] )
          enum.feed select_on

          expect( enum.next ).to eq( [:e, 5 ] )
          enum.feed reject_on

          stop_iteration_ex = nil
          begin
            enum.next
          rescue StopIteration => ex 
            stop_iteration_ex = ex
          end

          result = stop_iteration_ex.result

          expect( result.inner_map ).to eq( {
            'a' => 'AAA',
            :d  =>  4
          } )
        end
      end

      describe '#select' do
        include_examples "selects/rejects entries", :select, true, false
      end

      describe '#reject' do
        include_examples "selects/rejects entries", :reject, false, true
      end
    end

    describe '#each_key' do
      before do
        subject[ 1     ] = 1
        subject['two'  ] = { a: 1 }
        subject[:three ] = [ 9 ]
      end

      describe "given a block argument" do
        it "provides enumeration of its keys in same order as added" do
          keys = []
          subject.each_key do |key| ; keys << key ; end
          expect( keys ).to eq(
            [ 1, 'two', :three ]
          )
        end

        it "returns the target map" do
          expect( subject.each_key{ 'foo' } ).to eq( subject )
        end
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

      context "when given a block argument" do
        it "provides enumeration of externalizations of its values in same order as added" do
          values = []

          subject.each_value do |value| ; values << value ; end

          expect( values.length ).to eq( 3 )
          expect( values[ 0 ] ).to eq( 1 )
          expect( values[ 1 ].inner_map ).to eq( { a: 1 } )
          expect( values[ 2 ].inner_array ).to eq( [ 9 ] )
        end

        it "returns the target map" do
          expect( subject.each_value{ 'foo' } ).to equal( subject )
        end
      end

      it "provides an enumerator over externalizations of its values in same order as added when not given a block" do
        enum = subject.each_value

        expect( enum.next ).to eq( 1 )
        expect( enum.next.inner_map ).to eq( { a: 1 } )
        expect( enum.next.inner_array ).to eq( [ 9 ] )
        expect{ enum.next }.to raise_exception( StopIteration )
      end
    end

    describe '#clear' do
      before do
        inner_map.merge( a: 1, b: 2 )
      end

      it "removes all entries from the inner-map Hash" do
        subject.clear
        expect( inner_map ).to be_empty
      end

      it "returns the target Map" do
        expect( subject.clear ).to equal( subject )
      end
    end

    describe "#replace" do
      it "replaces the contents of the inner-map Hash with the contents of the map-deconstruction of the given object" do
        inner_map.merge original: 'contents'
        replacement_data = described_class.new(
          :new => 'stuff',
          'More new' => :stuff
        )

        result = subject.replace( replacement_data )

        expect( subject.inner_map ).to eq( {
          :new => 'stuff',
          'More new' => :stuff
        } )
      end

      it "returns the target map object" do
        expect( subject.replace( {'a' => 'aa'} ) ).to equal( subject )
      end
    end

    describe '#assoc' do
      it "returns nil for a key value, the conformation of which != any key in the inner-map hash" do
        subject[:aaa ] = 'A'
        subject['bbb'] = ['b']
        expect( subject.assoc(:x ) ).to be_nil
      end

      it "given the key, externalized-value for a matching entry, given a key, the inernalization of which is == to the key of the entry" do
        subject[:aaa ] = 'A'
        subject[ 10  ] = ['b']

        key, value = subject.assoc( 10.0 )

        expect( key ).to eql( 10 )
        expect( value.inner_array ).to eq( ['b'] )
      end

      it "finds matching key, externalized-value for entry with key matching conformation of the given key" do
        subject[:aaa ] = 'A'
        subject[:bbb ] = ['b']

        key, value = subject.assoc('bbb')

        expect( key ).to eql(:bbb )
        expect( value ).to eq(
          MWIA::List.new( ['b'] )
        )
      end
    end

    describe '#rassoc' do
      before do
        inner_map[ 1 ] = 1
        inner_map[:b ] = {:bb  => 'B'}
      end

      it "returns nil for a value, the externalization of which is != the externalization of any value in the inner-map hash" do
        result = subject.rassoc( 2 )
        expect( result ).to eq( nil )
      end

      it "returns the key, externalization-value pair for an entry with externalization-value == the externalization of the given value" do
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

      it "returns false for a value, the externalization of which is != the externalization of any value in the inner-map hash" do
        expect( subject.has_value?( 2 ) ).to eq( false )
      end

      it "returns true for a value, the externalization of which is == the externalization of any value in the inner-map hash" do
        map = described_class.new( {'bb' => 'B'} )
        expect( subject.has_value?( map ) ).to eq( true )
      end
    end

    describe 'map-merging' do
      before do
        inner_map.merge! \
           1  => 'one',
          'a' => {:aa => 'AA'},
          :b  => 'B'
      end

      let(:given_map ) { double(:given_map ) }

      context "given a mqp-analog argument with keys, the target-conformations of which do not match keys in the inner-map hash" do
        before do
          first_pair  = ['c', 'C']
          second_pair = [:d , described_class.new('dd' => 'DD') ]
          allow( given_map ).to receive(:each_pair ).
            and_yield( first_pair ).
            and_yield( second_pair )
        end

        let(:expected_merged_inner_map ) { {
           1  => 'one',
          'a' => {:aa => 'AA'},
          :b  => 'B',
          'c' => 'C',
          :d  => {'dd' => 'DD'}
        } }

        describe '#merge!' do
          it "stores the externalization of the value for the key from each entry in the given object" do
            subject.merge! given_map
            expect( inner_map ).to eq( expected_merged_inner_map )
          end

          it "returns the target map object" do
            expect( subject.merge!(given_map) ).to equal( subject )
          end

          it "does not invoke a given block" do
            subject.merge!(given_map){
              fail "block was called"
            }
          end
        end

        describe '#merge' do
          it "returns a new map with inner-map hash having entries from the target and entries for keys with externalized values from the given object" do
            merge_result = subject.merge( given_map )
            expect( merge_result.inner_map ).not_to equal( subject.inner_map )
            expect( merge_result.inner_map ).to eq( expected_merged_inner_map )
          end

          it "does not invoke a given block" do
            subject.merge(given_map){
              fail "block was called"
            }
          end
        end
      end

      context "given a mqp-analog argument with keys, the target-conformations of which match keys in the inner-map hash" do
        before do
          first_pair  = [ 1 , 'uno']
          second_pair = [:a , 'A' ]
          third_pair  = ['b',  described_class.new('bb' => 'BB') ]
          allow( given_map ).to receive(:each_pair ).
            and_yield( first_pair ).
            and_yield( second_pair ).
            and_yield( third_pair )
        end

        let(:expected_merged_inner_map ) { {
           1  => 'uno',
          'a' => 'A',
          :b  => {'bb' => 'BB'}
        } }

        describe '#merge!' do
          it "stores the externalization of the value for the target-conformations of the key from each entry in the given object" do
            subject.merge! given_map
            expect( inner_map ).to eq( expected_merged_inner_map )
          end

          it "returns the target map object" do
            expect( subject.merge!(given_map) ).to equal( subject )
          end

          it "passes to the block, the conformed key and externalized values from corresponding entries in the target and given, then stores the internalizations of the block result into the target's inner-map" do
            subject.merge!( given_map ){ |key, old_val, new_val|
              described_class.new( key => [ old_val, new_val ] )
            }
            expect( subject.inner_map ).to eq( {
               1  => { 1  => ['one', 'uno'] },
              'a' => {'a' => [ described_class.new('aa' => 'AA'), 'A'] },
              :b  => {:b  => ['B', described_class.new('bb' => 'BB')] }
            } )
          end
        end

        describe '#merge' do
          it "returns a new map with entries having keys from the target and internalizations of values from entries in the given object with matching target-conformed keys" do
            merge_result = subject.merge( given_map )
            expect( merge_result.inner_map ).not_to equal( subject.inner_map )
            expect( merge_result.inner_map ).to eq( expected_merged_inner_map )
          end

          it "for each duplicate conformed key, passes the conformed key and externalized values from corresponding entries in the target and given, then produces a reult entry with internal the internalization of the block result in the result's inner-map" do
            merge_result = subject.merge( given_map ){ |key, old_val, new_val|
              described_class.new( key => [ old_val, new_val ] )
            }
            expect( merge_result.inner_map ).to eq( {
               1  => { 1  => ['one', 'uno'] },
              'a' => {'a' => [ described_class.new('aa' => 'AA'), 'A'] },
              :b  => {:b  => ['B', described_class.new('bb' => 'BB')] }
            } )
          end
        end
      end
    end

    describe '#shift' do
      it "returns the externalization of the inner-map hash's default externalized for an empty map" do
        # Yes, this does seem like WAT!? but is analogous to the
        # documented and actual behavior of Hash#shift, so we're
        # being consistent with that WAT.
        inner_map.default = { a: 1 }
        result = subject.shift
        expect( result.inner_map ).to eq( { a: 1 } )
      end

      it "removes an entry from the inner-map hash, returning an array of the key and externalized value of that entry." do
        inner_map.merge! \
          a: { value_for: :a },
          b: { value_for: :b }

        result = subject.shift
        expect( subject.length ).to eq( 1 )

        expect( result.first ).to eq(:a ).or eq(:b )
        expect( result.last.inner_map ).to eq( { value_for: result.first } )
      end
    end

    it "returns from #invert, a new map of the inversion of the inner-map hash" do
      inner_map.merge! \
        :a    => 'AA',
        'BB'  => :b,
        [ 3 ] => { x: 3 }

      expected_invs_inner_map = {
        'AA'     => :a,
        :b       => 'BB',
        { x: 3 } => [ 3 ]
      }

      inversion = subject.invert

      expect( inversion.inner_map ).to eq( expected_invs_inner_map )
    end

  end

end
