require 'spec_helper'

describe MapWithIndifferentAccess do

  describe '#new' do
    describe "with no arguments" do
      it "returns a new empty Map" do
        actual_map = MapWithIndifferentAccess.new
        expect( actual_map ).to be_kind_of( MapWithIndifferentAccess::Map )
        expect( actual_map ).to be_empty
      end
    end

    describe "with a Hash argument" do
      it "returns a new Map with the given hash as its #inner_map" do
        hash = {'a' => 1, :b => 2 }
        actual_map = MapWithIndifferentAccess.new( hash )
        expect( actual_map ).to be_kind_of( MapWithIndifferentAccess::Map )
        expect( actual_map.inner_map ).to equal( hash )
      end
    end
  end

end
