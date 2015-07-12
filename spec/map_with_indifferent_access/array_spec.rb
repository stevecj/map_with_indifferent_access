require 'spec_helper'

describe MapWithIndifferentAccess::Array do
  let( :inner_array ) { subject.inner_array }

  it "can be constructed as a wrapper around an existing array" do
    inner_a = []
    array = described_class.new( inner_a )
    expect( array.inner_array ).to equal( inner_a )
  end

  it "can be constructed as a wrapper asound an implicitly-created hash" do
    array = described_class.new
    expect( array.inner_array ).to be_kind_of( Array )
  end

  it "can be constructed as a new wrapper around an existing wrapped array" do
    inner_a = []
    original_array = described_class.new( inner_a )
    array = described_class.new( original_array )
    expect( array ).not_to equal( original_array )
    expect( array.inner_array ).to equal( inner_a )
  end

  it "cannot be constructed with an un-array-like argument to ::new" do
    expect{
      described_class.new( 1 )
    }.to raise_exception( NoMethodError )
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

  it "stores an item by index into its inner array" do
    subject[3] = :abc
    expect( inner_array[3] ).to eq( :abc )
  end

  it "reads an item by index from its inner array" do
    inner_array[2] = :abc
    expect( subject[2] ).to eq( :abc )
  end

  it "reflects a hash-type item by index as wrapped" do
    inner_array[3] = {a: 1}
    expect( subject[3] ).to be_kind_of( MapWithIndifferentAccess )
    expect( subject[3].inner_map ).to eq( {a: 1} )
  end

  it "reflects an array-type item by index as wrapped" do
    inner_array[3] = [:a, :b]
    expect( subject[3] ).to be_kind_of( described_class )
  end

  it "allows items to be pushed onto its end" do
    subject << 1
    subject.push 2, 3
    expect( subject.inner_array ).to eq( [1, 2, 3] )
  end

  it "provides its number of entries via #length" do
    subject.push( 1, {a: 2} )
    expect( subject.length ).to eq( 2 )
  end

  it "has unequal instances via #== with wrapping-indifferently unequal item sequence" do
    subject <<
      1 <<
      { a: 2 } <<
      [ {'b' => 3} ]

    other = described_class.new( [
      1,
      { 'a' => :too },
      [ {b: 3} ]
    ] )

    expect( subject == other ).to eq( false )
  end

  it "has equal instances via #== with wrapping-indifferently equal item sequence" do
    subject <<
      1 <<
      { a: 2 } <<
      [ {'b' => 3} ]

    other = described_class.new( [
      1,
      { 'a' => 2 },
      [ {b: 3} ]
    ] )

    expect( subject == other ).to eq( true )
  end

  it "is enumerable over items" do
    subject <<
      1 <<
      { a: 2 } <<
      [ {'b' => 3} ]

    items = []
    subject.each do |item| ; items << item ; end

    expect( items ).to eq( [
      1,
      MapWithIndifferentAccess.new(a: 2), 
      MapWithIndifferentAccess::Array.new( [{b: 3}] )
    ] )

    expect( subject.entries ).to eq( items )
  end

end
