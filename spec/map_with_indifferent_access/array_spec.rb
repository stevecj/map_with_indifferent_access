require 'spec_helper'

module MWIA_ArraySpec
  include MapWithIndifferentAccess::WithConveniences

describe MWIA::Array do
  let( :inner_array ) { subject.inner_array }

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
    }.to raise_exception( NoMethodError )
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

  describe "indexed value access" do
    it "stores the internalization of a given item by the given index into its inner array" do
      map = MWIA.new
      subject[ 2 ] = map
      expect( inner_array[ 2 ] ).to equal( map.inner_map )
    end

    it "reads the externalization of the item by index from its inner array" do
      inner_array[ 3 ] = { a: 1 }
      expect( subject[ 3 ] ).to be_kind_of( MWIA )
      expect( subject[ 3 ].inner_map ).to eq( { a: 1 } )
    end
  end

  describe "#push" do
    it "push the internalization of given items onto the end of the inner array" do
      wrapped_hash_map = MWIA.new

      subject << 1
      subject << wrapped_hash_map
      subject.push 1, wrapped_hash_map

      expect( inner_array.length ).to eq( 4 )
      expect( inner_array[ 0 ] ).to equal( 1 )
      expect( inner_array[ 1 ] ).to equal( wrapped_hash_map.inner_map )
      expect( inner_array[ 2 ] ).to equal( 1 )
      expect( inner_array[ 3 ] ).to equal( wrapped_hash_map.inner_map )
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

  it "provides its number of entries via #length" do
    subject.push( 1, { a: 2 } )
    expect( subject.length ).to eq( 2 )
  end

  it "has unequal instances via #== with corresponding entries, the externalization of which are not all equal" do
    inner_array <<
      1 <<
      { a: 2 } <<
      [ {'b' => 3 } ]

    other = described_class.new( [
      1,
      {'a' => :too },
      [ { b: 3 } ]
    ] )

    expect( subject == other ).to eq( false )
  end

  it "has equal instances via #== with corresponding entries, the externalization of which are all equal" do
    inner_array <<
      1 <<
      { a: 2 } <<
      [ {'b' => 3 } ]

    other = described_class.new( [
      1,
      {'a' => 2 },
      [ { b: 3 } ]
    ] )

    expect( subject == other ).to eq( true )
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
      MWIA.new( a: 2 ), 
      MWIA::Array.new( [ { b: 3 } ] )
    ] )

    expect( subject.entries ).to eq( items )
  end

end

end
