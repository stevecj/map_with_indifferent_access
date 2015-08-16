require 'spec_helper'

module KeySymbolizationSpec
  include MapWithIndifferentAccess::WithConveniences

  class HashAnalog  < Struct.new(:to_hash )
    def each_pair ; end
  end

  class ArrayAnalog < Struct.new(:to_ary  )
  end

  describe MWIA::KeySymbolization do
    describe "deep_symbolize" do
      let(:shallow_hash ){ {
        'a' => 11,
        :b  => 22,
         3  => 33
      } }

      let(:shallow_mwia ){
        MWIA.new( shallow_hash )
      }

      let(:shallow_hash_analog) {
        HashAnalog.new( shallow_hash )
      }

      let(:array ){ [
        shallow_hash.dup,
        shallow_mwia,
        [ 31, 32, 33 ],
        MWIA::Array.new( [ 41, 42 ] ),
        5,
      ] }

      let(:mwia_array ){
        MWIA::Array.new( array )
      }

      let(:array_analog) {
        ArrayAnalog.new( array )
      }

      let(:nested_hash ){ {
        :shallow_h  => shallow_hash.dup,
        'shallow_m' => shallow_mwia,
        :array      => array,
        'number'    => 99
      } }

      it "returns the given object that is not hashlike or arraylike" do
        expect( subject.deeply_symbolize( 123 ) ).to eq( 123 )
        expect( subject.deeply_symbolize('abc') ).to eq('abc')
      end

      it "returns a new Hash copy of the given Hash with keys symbolized" do
        result = subject.deeply_symbolize( shallow_hash )
        expect( result ).to be_kind_of( Hash )
        expect( result ).to eq( {
          :a    => 11,
          :b    => 22,
          :'3'  => 33
        } )
      end

      it "returns a new MWIA copy of the given MWIA with keys symbolized" do
        result = subject.deeply_symbolize( shallow_mwia )
        expect( result ).to be_kind_of( MWIA )
        expect( result.inner_map ).to eq( {
          :a    => 11,
          :b    => 22,
          :'3'  => 33
        } )
      end

      it "returns a new Hash copy of the given hashlike object with keys symbolized" do
        result = subject.deeply_symbolize( shallow_hash_analog )
        expect( result ).to be_kind_of( Hash )
        expect( result ).to eq( {
          :a    => 11,
          :b    => 22,
          :'3'  => 33
        } )
      end

      it "returns a new Array copy of the given array with symbolized-key copies of hashlike and arraylike items" do
        result = subject.deeply_symbolize( array )
        expect( result ).to be_kind_of( ::Array )
        expect( result.length ).to eq( 5 )
        expect( result[ 0 ] ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result[ 1 ].inner_map ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result[ 2 ] ).to eq( [ 31, 32, 33 ] )
        expect( result[ 3 ].inner_array ).to eq( [ 41, 42 ] )
        expect( result[ 4 ] ).to eq( 5 )
      end

      it "returns a new Array copy of the given array with symbolized-key copies of hashlike and arraylike items" do
        result = subject.deeply_symbolize( mwia_array )
        expect( result ).to be_kind_of( MWIA::Array )
        expect( result.length ).to eq( 5 )
        expect( result.inner_array[ 0 ] ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result.inner_array[ 1 ].inner_map ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result.inner_array[ 2 ] ).to eq( [ 31, 32, 33 ] )
        expect( result.inner_array[ 3 ].inner_array ).to eq( [ 41, 42 ] )
        expect( result[ 4 ] ).to eq( 5 )
      end

      it "returns a new Array copy of the given arraylike object with symbolized-key copies of hashlike and arraylike items" do
        result = subject.deeply_symbolize( array_analog )
        expect( result ).to be_kind_of( ::Array )
        expect( result.length ).to eq( 5 )
        expect( result[ 0 ] ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result[ 1 ].inner_map ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result[ 2 ] ).to eq( [ 31, 32, 33 ] )
        expect( result[ 3 ].inner_array ).to eq( [ 41, 42 ] )
        expect( result[ 4 ] ).to eq( 5 )
      end

      it "returns a new Hash copy of the given Hash with hashlike/arraylike contents deeply replaced with symbolized-key copies" do
        result = subject.deeply_symbolize( nested_hash )
        expect( result.keys ).to eq( [
          :shallow_h, :shallow_m, :array, :number
        ] )
        expect( result[:shallow_h ] ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result[:shallow_m ].inner_map ).to eq( {
          :a => 11, :b => 22, :'3' => 33
        } )
        expect( result[:array ] ).to eq( [
          {:a => 11, :b => 22, :'3' => 33 },
          MWIA.new(:a => 11, :b => 22, :'3' => 33 ),
          [ 31, 32, 33 ],
          MWIA::Array.new( [ 41, 42 ] ),
          5
        ] )
      end
    end
  end

end
