require 'spec_helper'

module MWIA_ValuesSpec
  include MapWithIndifferentAccess::WithConveniences

  describe MapWithIndifferentAccess::Values do

    describe '#externalize / #>>' do
      it "returns the given object when not an Array, Hash, MWIA, or MWIA::List" do
        expect( subject >>  nil ).to eq( nil )
        expect( subject >> 'abc').to eq('abc')
        expect( subject >>  123 ).to eq( 123 )

        timeval = Time.new( 2010,11,16, 10,45,59 )
        expect( subject >> timeval ).to eq( timeval )
      end
    end

    it "returns an MWIA-wrapped instance of the given Hash" do
      given_hash = { a: 1 }
      result = subject >> given_hash
      expect( result.inner_map ).to equal( given_hash )
    end

    it "returns an MWIA::List-wrapped instance of the given Array" do
      given_array = [ 1, 2, 3 ]
      result = subject >> given_array
      expect( result.inner_array ).to equal( given_array )
    end

    it "returns the given MWIA instance" do
      result = subject >> subject
      expect( result ).to equal( subject )
    end

    it "returns the given MWIA::List instance" do
      given_array_wrapper = MWIA::List.new
      result = subject >> given_array_wrapper
      expect( result ).to equal( given_array_wrapper )
    end

    describe '#internalize / #<<' do
      it "returns the given object when not an MWIA or MWIA::List" do
        p subject
        expect( subject <<  nil  ).to eq(  nil  )
        expect( subject << 'abc' ).to eq( 'abc' )
        expect( subject <<  123  ).to eq(  123  )
        expect( subject << [ 9 ] ).to eq( [ 9 ] )
      end

      it "returns the inner hash map from a given MWIA" do
        map = MWIA.new
        expect( subject << map ).to equal( map.inner_map )
      end

      it "returns the inner array from a given MWIA::List" do
        wrapped_array = MWIA::List.new
        expect( subject << wrapped_array ).to equal( wrapped_array.inner_array )
      end
    end

  end

end
