require 'spec_helper'

describe MapWithIndifferentAccess::Array do
  subject { described_class.new( array ) }
  let( :array ) { [] }

  it "can be converted from an instance of its class, returning the given map" do
    map = described_class::try_convert( subject )
    expect( map ).to equal( subject )
  end

  it "can be converted from an array, wrapping the given array" do
    array = []

    hwia_array = described_class::try_convert( array )

    expect( hwia_array ).to be_kind_of( described_class)
    expect( hwia_array.inner_array ).to equal( array )
  end

  it "cannot be converted from an arbitrary object" do
    expect( described_class::try_convert( nil ) ).to be_nil
    expect( described_class::try_convert( 1   ) ).to be_nil
    expect( described_class::try_convert( {}  ) ).to be_nil
  end

  it "delegates storing an item by index" do
    subject[3] = :abc
    expect( array[3] ).to eq( :abc )
  end

  it "delegates reading an item by index" do
    array[2] = :abc
    expect( subject[2] ).to eq( :abc )
  end

  it "reflects hash-type item by index as wrapped" do
    array[3] = {a: 1}
    expect( subject[3] ).to be_kind_of( MapWithIndifferentAccess )
    expect( subject[3].inner_map ).to eq( {a: 1} )
  end

  it "reflects array-type item by index as wrapped" do
    array[3] = [:a, :b]
    expect( subject[3] ).to be_kind_of( described_class )
  end

  it "allows items to be pushed onto its end" do
    subject << 1
    subject.push 2, 3
    expect( subject.inner_array ).to eq( [1, 2, 3] )
  end

  it "provides number of entries via #length" do
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
