require 'spec_helper'
require_relative 'wraps_collection_examples'

module MapWithIndifferentAccess

  describe List do
    let( :inner_array ) { subject.inner_array }
    let( :inner_collection ) { inner_array }

    it "can be constructed as a wrapper around an existing array" do
      inner_a = []
      array = described_class.new( inner_a )
      expect( array.inner_array ).to equal( inner_a )
    end

    it "can be constructed as a wrapper asound an implicitly-created array" do
      array = described_class.new
      expect( array.inner_array ).to be_kind_of( Array )
    end

    it "can be constructed as a new wrapper around a the inner array of an existing wrapped array" do
      inner_a = []
      original_array = described_class.new( inner_a )
      array = described_class.new( original_array )
      expect( array ).not_to equal( original_array )
      expect( array.inner_array ).to equal( inner_a )
    end

    it "cannot be constructed by passing an un-array-like argument to ::new" do
      expect{
        described_class.new( 1 )
      }.to raise_exception( ArgumentError )
    end

    it "deconstructs a wrapped-array instance to its inner array" do
      result = described_class.try_deconstruct( subject )
      expect( result ).to equal( subject.inner_array )
    end

    it "deconstructs an ::Array to itself" do
      array = []
      result = described_class.try_deconstruct( array )
      expect( result ).to equal( array )
    end

    it "deconstructs an object other than an array or wrapped array to `nil`" do
      expect( described_class.try_deconstruct( 10   ) ).to eq( nil )
      expect( described_class.try_deconstruct( true ) ).to eq( nil )
      expect( described_class.try_deconstruct('xy'  ) ).to eq( nil )
      expect( described_class.try_deconstruct( {}   ) ).to eq( nil )
    end

    it "can be converted from an instance of its class, returning the given array" do
      array = described_class::try_convert( subject )
      expect( array ).to equal( subject )
    end

    it "cannot be converted from an un-array-like object" do
      expect( described_class::try_convert( nil ) ).to be_nil
      expect( described_class::try_convert( 1   ) ).to be_nil
      expect( described_class::try_convert( {}  ) ).to be_nil
    end

    it "can be converted from an array, wrapping the given array" do
      given_array = []

      array = described_class::try_convert( given_array )

      expect( array ).to be_kind_of( described_class)
      expect( array.inner_array ).to equal( given_array )
    end

    describe '#[]=' do
      context "given an integer index" do
        it "stores the internalization of a given value at the given index in its inner array" do
          array_val = List.new
          subject[ 2 ] = array_val
          expect( inner_array[ 2 ] ).to equal( array_val.inner_array )
        end
      end

      context "given a range index" do
        before do
          inner_array.replace [ 0, 1, 2, 3, 4 ]
        end

        let(:map_val ){ Map.new }

        it "replaces the range of entries with a single entry containing the internalization of a given value" do
          subject[ 2..3 ] = map_val
          expect( inner_array.length ).to eq( 4 )
          expect( inner_array[ 0..1 ] ).to eq( [ 0, 1 ] )
          expect( inner_array[ 2 ] ).to equal( map_val.inner_map )
          expect( inner_array[ 3 ] ).to eq( 4 )
        end

        it "replaces the range of entries with entries containing internalizations of entries in the given Array" do
          subject[ 2..3 ] = [ 22, map_val, 99 ]
          expect( inner_array.length ).to eq( 6 )
          expect( inner_array[ 0..2 ] ).to eq( [ 0, 1, 22 ] )
          expect( inner_array[ 3 ] ).to equal( map_val.inner_map )
          expect( inner_array[ 4..5 ] ).to eq( [ 99, 4 ] )
        end

        it "replaces the range of entries with entries containing internalizations of entries in the given List" do
          subject[ 2..3 ] = List.new( [22, map_val, 99] )
          expect( inner_array.length ).to eq( 6 )
          expect( inner_array[ 0..2 ] ).to eq( [ 0, 1, 22 ] )
          expect( inner_array[ 3 ] ).to equal( map_val.inner_map )
          expect( inner_array[ 4..5 ] ).to eq( [ 99, 4 ] )
        end
      end

      context "given a starting index and a range length" do
        before do
          inner_array.replace [ 0, 1, 2, 3, 4 ]
        end

        let(:map_val ){ Map.new }

        it "replaces the range of entries with a single entry containing the internalization of a given value" do
          subject[ 2, 2 ] = map_val
          expect( inner_array.length ).to eq( 4 )
          expect( inner_array[ 0..1 ] ).to eq( [ 0, 1 ] )
          expect( inner_array[ 2 ] ).to equal( map_val.inner_map )
          expect( inner_array[ 3 ] ).to eq( 4 )
        end

        it "replaces the range of entries with entries containing internalizations of entries in the given Array" do
          subject[ 2, 2 ] = [ 22, map_val, 99 ]
          expect( inner_array.length ).to eq( 6 )
          expect( inner_array[ 0..2 ] ).to eq( [ 0, 1, 22 ] )
          expect( inner_array[ 3 ] ).to equal( map_val.inner_map )
          expect( inner_array[ 4..5 ] ).to eq( [ 99, 4 ] )
        end

        it "replaces the range of entries with entries containing internalizations of entries in the given List" do
          subject[ 2, 2 ] = List.new( [22, map_val, 99] )
          expect( inner_array.length ).to eq( 6 )
          expect( inner_array[ 0..2 ] ).to eq( [ 0, 1, 22 ] )
          expect( inner_array[ 3 ] ).to equal( map_val.inner_map )
          expect( inner_array[ 4..5 ] ).to eq( [ 99, 4 ] )
        end
      end
    end

    describe '#at' do
      it "reads the externalization of the item by index from its inner array" do
        inner_array[ 3 ] = { a: 1 }
        result = subject.at( 3 )
        expect( result.inner_map ).to eq( { a: 1 } )
      end
    end

    describe '#[]' do
      before do
        inner_array.replace [
          0,
          1,
          { c: 2 },
          3
        ]
      end

      it "reads the externalization of the item at a given index from its inner array" do
        expect( subject[ 2 ].inner_map ).to eq( { c: 2 } )
      end

      it "reads an List of the items at a given range of indexes in its inner array" do
        result = subject[ 1..2 ]
        expect( result.inner_array ).to eq( [
          1,
          { c: 2 }
        ] )
      end

      it "reads an List of the items in the range of index in its inner array with the given starting index and length" do
        result = subject[ 2, 2 ]
        expect( result.inner_array ).to eq( [
          { c: 2 },
          3
        ] )
      end
    end

    describe '#push / #<<' do
      let(:wrapped_hash_map ){ Map.new }

      it "pushes the internalizations of given items onto the end of the inner array" do
        subject << 'a'
        subject << wrapped_hash_map
        subject.push 'b', wrapped_hash_map

        expect( inner_array.length ).to eq( 4 )
        expect( inner_array[ 0 ] ).to eq('a')
        expect( inner_array[ 1 ] ).to equal( wrapped_hash_map.inner_map )
        expect( inner_array[ 2 ] ).to eq('b')
        expect( inner_array[ 3 ] ).to equal( wrapped_hash_map.inner_map )
      end

      it "returns the target" do
        result = subject.push('x')
        expect( result ).to equal( subject )
      end
    end

    describe '#unshift' do
      it "pushes the internalizations of given items into the beginning of the inner array" do
        wrapped_hash_map = Map.new

        inner_array[0] = 'x'

        subject.unshift 1, wrapped_hash_map

        expect( inner_array.length ).to eq( 3 )
        expect( inner_array[ 0 ] ).to eq( 1 )
        expect( inner_array[ 1 ] ).to equal( wrapped_hash_map.inner_map )
        expect( inner_array[ 2 ] ).to eq('x')
      end

      it "returns the target" do
        result = subject.unshift('x')
        expect( result ).to equal( subject )
      end
    end

    describe '#insert' do
      it "inserts the internalizations of given items before the element with the given index in the inner array" do
        wrapped_hash_map = Map.new

        inner_array.replace ['a', 'b', 'c', 'd']

        subject.insert 2, 99, wrapped_hash_map

        expect( inner_array.length ).to eq( 6 )
        expect( inner_array[ 0..2 ] ).to eq( ['a', 'b', 99 ] )
        expect( inner_array[ 3 ] ).to equal( wrapped_hash_map.inner_map )
        expect( inner_array[ 4..5 ] ).to eq( ['c', 'd'] )
      end

      it "returns the target" do
        result = subject.insert( 0, 'x')
        expect( result ).to equal( subject )
      end
    end

    describe "#values_at" do
      before do
        inner_array.replace [ 1, 2, 3, 4 ]
      end

      it "acts like Array#values_at, but returns an List" do
        # Hand-waving on the description because the behavior
        # of Array#values at is Byzantine, and the implementation
        # directly uses Array to get all of that behavior.
        result = subject.values_at( 3, 0..1, 3..9, 2 )
        expect( result.inner_array ).to eq( [
          4, 1, 2, 4, nil, 3
        ] )
      end
    end

    describe '#fetch' do
      it "reads the externalization of the item by index from its inner array" do
        inner_array[ 3 ] = { a: 1 }
        result = subject.fetch( 3 )
        expect( result.inner_map ).to eq( { a: 1 } )
      end

      it "raises an IndexError for an out-of-bounds index with no default or block argument given" do
        inner_array << 0 << 1
        expect{ subject.fetch 2 }.to raise_exception( IndexError )
        expect{ subject.fetch -3 }.to raise_exception( IndexError )
      end

      it "returns the externalization of the given default value for an out-of-bounds index" do
        inner_array << 0 << 1
        result = subject.fetch( 2, { the: 'default'} )
        expect( result.inner_map ).to eq( { the: 'default'} )
      end

      it "passes the given index to the given block, and returns the externalization of the block result for an out-of-bounds index" do
        inner_array << 0 << 1
        result = subject.fetch( 2 ){ |idx| { index: idx } }
        expect( result.inner_map ).to eq( { index: 2} )
      end
    end

    describe "#shift" do
      before do
        inner_array.replace [
          { a: 1 },
          2,
          3
        ]
      end

      it "removes the first item from the inner array, and returns the externalization of that value when no argument is given" do
        result = subject.shift
        expect( inner_array ).to eq( [ 2, 3 ] )
        expect( result.inner_map ).to eq( { a: 1 } )
      end

      it "removes the given number of initial items from the inner array, and returns an List of those values" do
        result = subject.shift( 2 )
        expect( inner_array ).to eq( [ 3 ] )
        expect( result.inner_array ).to eq( [
          { a: 1 },
          2
        ] )
      end
    end

    describe "#pop" do
      before do
        inner_array.replace [
          1,
          2,
          { c: 3 }
        ]
      end

      it "removes the last item from the inner array, and returns the externalization of that value when no argument is given" do
        result = subject.pop
        expect( inner_array ).to eq( [ 1, 2 ] )
        expect( result.inner_map ).to eq( { c: 3 } )
      end

      it "removes the given number of items from the inner array, and returns an List of those values" do
        result = subject.pop( 2 )
        expect( inner_array ).to eq( [ 1 ] )
        expect( result.inner_array ).to eq( [
          2,
          { c: 3 }
        ] )
      end
    end

    describe "#delete_at" do
      before do
        inner_array.replace [
          1,
          { b: 2 },
          3
        ]
      end

      it "removes the item at the given index from the inner array, and returns the externalization of that value" do
        result = subject.delete_at( 1 )
        expect( inner_array ).to eq( [ 1, 3 ] )
        expect( result.inner_map ).to eq( { b: 2 } )
      end
    end

    it_behaves_like "a collection wrapper"

    describe '#tainted?' do
      it "returns false when its inner-array is not tainted" do
        expect( subject.tainted? ).to eq( false )
      end

      it "returns true when its inner-array hash is tainted" do
        inner_array.taint
        expect( subject.tainted? ).to eq( true )
      end
    end

    describe '#taint' do
      before do
        subject.taint
      end

      it "causes its inner-array to be tainted" do
        expect( inner_array ).to be_tainted
      end
    end

    describe '#untaint' do
      before do
        inner_array.taint
        subject.untaint
      end

      it "causes its inner-array to be untainted" do
        expect( inner_array ).not_to be_tainted
      end
    end

    describe '#untrusted?' do
      it "returns false when its inner-array is trusted" do
        expect( subject.untrusted? ).to eq( false )
      end

      it "returns true when its inner-array is not trusted" do
        inner_array.untrust
        expect( subject.untrusted? ).to eq( true )
      end
    end

    describe '#trust' do
      before do
        inner_array.untrust
        subject.trust
      end

      it "causes its inner-array to be trusted" do
        expect( inner_array ).not_to be_untrusted
      end
    end

    describe '#untrust' do
      before do
        subject.untrust
      end

      it "causes its inner-array to be untrusted" do
        expect( inner_array ).to be_untrusted
      end
    end

    describe '#freeze' do
      it "freezes the inner-array along with the List" do
        subject.freeze
        expect( inner_array ).to be_frozen
      end

      it "returns the List" do
        expect( subject.freeze ).to equal( subject )
      end
    end

    describe '#_frozen?' do
      it "returns false when neither the List nor its inner-array is frozen" do
        expect( subject._frozen? ).to eq( false )
      end

      it "returns false when the List is not frozen and its inner-array is frozen" do
        inner_array.freeze
        expect( subject._frozen? ).to eq( false )
      end

      it "returns true when the List is frozen" do
        subject.freeze
        expect( subject._frozen? ).to eq( true )
      end
    end

    describe '#frozen?' do
      it "returns false when its inner-array is not frozen" do
        expect( subject.frozen? ).to eq( false )
      end

      it "returns true when its inner-array is frozen" do
        inner_array.freeze
        expect( subject.frozen? ).to eq( true )
      end
    end

    describe "#delete" do
      before do
        inner_array.replace [
          1,
          { x: 99 },
          3,
          {'x' => 99 },
          5
        ]
      end

      context "given a value that does not match any items in the array" do
        it "without a block argument, does not remove any items from the inner array and returns nil" do
          result = subject.delete( 'z' )
          expect( subject.length ).to eq( 5 )
          expect( result ).to eq( nil )
        end

        it "does not remove any items from the inner array, passes the given value to the given block, and returns the externalization of the block call result" do
          result = subject.delete( 'z' ){ |v|
            { value: v }
          }
          expect( subject.length ).to eq( 5 )
          expect( result.inner_map ).to eq( { value: 'z' } )
        end
      end

      context "given a value, the externalization of which is equal to the externalizartions of multiple items in the inner array" do
        it "deletes matching items from the inner array and returns the externalization of the last match" do
          result = subject.delete( { x: 99 } )
          expect( result.inner_map ).to eq( {'x' => 99 } )
          expect( inner_array ).to eq( [ 1, 3, 5 ] )
        end
      end
    end

    describe '#uniq' do
      before do
        inner_array.replace build_initial_content
      end

      def build_initial_content
        [
          1,
          {'a' => 1 },
          {'a' => 1 },
          {:a  => 1 },
          1,
          {:b => 2 },
          Map.new(:b => 2 ),
          Map.new(:b => 2 ),
        ]
      end

      it "returns a new instance with inner array containing unique entries from the target compared using #hash and #eql?" do
        actual_result = subject.uniq
        expected_result = [
          1,
          {'a' => 1 },
          {:a  => 1 },
          {:b => 2 },
          Map.new(:b => 2 ),
        ]
        expect( actual_result ).to eq( expected_result )
      end
    end

    it "provides its number of entries via #length" do
      subject.push( 1, { a: 2 } )
      expect( subject.length ).to eq( 2 )
    end

    describe '#==' do
      before do
        inner_array <<
          1 <<
          { a: 2 } <<
          [ {'b' => 3 } ]
      end

      it "returns false of a non-array object" do
        expect( subject == 'abc' ).to eq( false )
      end

      it "returns false for an List with corresponding entries, the externalizations of which are not all equal" do
        other = described_class.new( [
          1,
          {'a' => :too },
          [ { b: 3 } ]
        ] )

        expect( subject == other ).to eq( false )
      end

      it "returns false for an ::Array with corresponding entries, the externalizations of which are not all equal" do
        other = [
          1,
          {'a' => :too },
          [ { b: 3 } ]
        ]

        expect( subject == other ).to eq( false )
      end

      it "returns false for an List with corresponding entries, the externalizations of which are not all equal" do
        other = described_class.new( [
          1,
          {'a' => :too },
          [ { b: 3 } ]
        ] )

        expect( subject == other ).to eq( false )
      end

      it "returns true for an ::Array with corresponding entries, the externalizations of which are all equal" do
        other = [
          1,
          {'a' => 2 },
          [ { b: 3 } ]
        ]

        expect( subject == other ).to eq( true )
      end

      it "returns true for an List with corresponding entries, the externalizations of which are all equal" do
        other = described_class.new( [
          1,
          {'a' => 2 },
          [ { b: 3 } ]
        ] )

        expect( subject == other ).to eq( true )
      end
    end

    describe '#eql?' do
      before do
        inner_array <<
          1 <<
          Map.new('b' => 2 )
      end

      it "returns false, given an object that is not an List" do
        expect( subject.eql?( inner_array ) ).to eq( false )
      end

      it "returns false, given an List with an inner array not #eql? to its own" do
        other = List.new( [
          1,
          {'b' => 2 }
        ] )
        expect( subject.eql?( other ) ).to eq( false )
      end

      it "returns true, given an List with an inner array that is #eql? to its own" do
        other = subject.dup
        expect( subject.eql?( other ) ).to eq( true )
      end
    end

    it "is enumerable over items" do
      subject <<
        1 <<
        { a: 2 } <<
        [ {'b' => 3 } ]

      items = []
      subject.each do |item| ; items << item ; end

      expect( items ).to eq( [
        1,
        Map.new( a: 2 ), 
        List.new( [ { b: 3 } ] )
      ] )

      expect( subject.entries ).to eq( items )
    end

  end

end
