require 'spec_helper'

module MapWithIndifferentAccess

  describe Values do

    describe '#externalize / #>>' do
      it "returns the given object when not an Array, Hash, Map, or List" do
        expect( subject >>  nil ).to eq( nil )
        expect( subject >> 'abc').to eq('abc')
        expect( subject >>  123 ).to eq( 123 )

        timeval = Time.new( 2010,11,16, 10,45,59 )
        expect( subject >> timeval ).to eq( timeval )
      end
    end

    it "returns a Map-wrapped instance of the given Hash" do
      given_hash = { a: 1 }
      result = subject >> given_hash
      expect( result.inner_map ).to equal( given_hash )
    end

    it "returns a List-wrapped instance of the given Array" do
      given_array = [ 1, 2, 3 ]
      result = subject >> given_array
      expect( result.inner_array ).to equal( given_array )
    end

    it "returns the given Map instance" do
      result = subject >> subject
      expect( result ).to equal( subject )
    end

    it "returns the given List instance" do
      given_array_wrapper = List.new
      result = subject >> given_array_wrapper
      expect( result ).to equal( given_array_wrapper )
    end

    describe '#internalize / #<<' do
      it "returns the given object when not an Map or List" do
        p subject
        expect( subject <<  nil  ).to eq(  nil  )
        expect( subject << 'abc' ).to eq( 'abc' )
        expect( subject <<  123  ).to eq(  123  )
        expect( subject << [ 9 ] ).to eq( [ 9 ] )
      end

      it "returns the inner hash map from a given Map" do
        map = Map.new
        expect( subject << map ).to equal( map.inner_map )
      end

      it "returns the inner array from a given List" do
        wrapped_array = List.new
        expect( subject << wrapped_array ).to equal( wrapped_array.inner_array )
      end
    end

  end

end
