require 'spec_helper'

describe MapWithIndifferentAccess::Array do
  subject { described_class.new( array ) }
  let( :array ) { [] }

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
end
