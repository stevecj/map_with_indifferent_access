require 'spec_helper'

module DeepKeyCoercerSpec
  include MapWithIndifferentAccess::WithConveniences

  module ExampleStrategy
    def self.needs_coercion?(key)
      key != 42
    end

    def self.coerce(key)
      "<#{key}>"
    end
  end

  class HashAnalog  < Struct.new(:to_hash )
    def each_pair ; end
  end

  class ArrayAnalog < Struct.new(:to_ary  )
  end

  describe MWIA::KeyCoercion::DeepCoercer do
    subject{ described_class.new( ExampleStrategy ) }

    let(:shallow_hash ){ {
      'a' => 11,
      'b' => 22,
       42 => 33
    } }

    let(:shallow_mwia ){
      MWIA.new( shallow_hash )
    }

    let(:shallow_hash_analog){
      HashAnalog.new( shallow_hash )
    }

    let(:array ){ [
      shallow_hash.dup,
      shallow_mwia,
      [ 31, 32 ],
      MWIA::Array.new( [ 41, 42 ] ),
      5,
    ] }

    let(:mwia_array ){
      MWIA::Array.new( array )
    }

    let(:array_analog){
      ArrayAnalog.new( array )
    }

    let(:nested_hash ){ {
      'shallow_h' => shallow_hash.dup,
      'shallow_m' => shallow_mwia,
      'array'     => array,
       42         => 99
    } }

    it "returns the given object that is not hashlike or arraylike" do
      expect( subject.call( 123 ) ).to eq( 123 )
      expect( subject.call('abc') ).to eq('abc')
    end

    it "returns a new Hash copy of the given Hash with keys coerced" do
      result = subject.call( shallow_hash )
      expect( result ).to be_kind_of( Hash )
      expect( result ).to eq( {
        '<a>' => 11,
        '<b>' => 22,
         42   => 33
      } )
    end

    it "returns a new MWIA copy of the given MWIA with keys symbolized" do
      result = subject.call( shallow_mwia )
      expect( result.inner_map ).to eq( {
        '<a>' => 11,
        '<b>' => 22,
         42   => 33
      } )
    end

    it "returns a new Hash copy of the given hashlike object with keys symbolized" do
      result = subject.call( shallow_hash_analog )
      expect( result ).to be_kind_of( Hash )
      expect( result ).to eq( {
        '<a>' => 11,
        '<b>' => 22,
         42   => 33
      } )
    end

    it "returns a new Array copy of the given array with deconstructed, symbolized-key copies of hashlike and arraylike items" do
      result = subject.call( array )
      expect( result ).to be_kind_of( ::Array )
      expect( result ).to eq( [
        {'<a>' => 11, '<b>' => 22, 42 => 33 },
        {'<a>' => 11, '<b>' => 22, 42 => 33 },
        [ 31, 32 ],
        [ 41, 42 ],
        5
      ] )
    end

    it "returns a new Array copy of the given MWIA::Array with deconstructed, symbolized-key copies of hashlike and arraylike items" do
      result = subject.call( mwia_array )
      expect( result.inner_array ).to eq( [
        {'<a>' => 11, '<b>' => 22, 42 => 33 },
        {'<a>' => 11, '<b>' => 22, 42 => 33 },
        [ 31, 32 ],
        [ 41, 42 ],
        5
      ] )
    end

    it "returns a new Array copy of the given arraylike object with deconstructed, symbolized-key copies of hashlike and arraylike items" do
      result = subject.call( array_analog )
      expect( result ).to be_kind_of( ::Array )
      expect( result ).to eq( [
        {'<a>' => 11, '<b>' => 22, 42 => 33 },
        {'<a>' => 11, '<b>' => 22, 42 => 33 },
        [ 31, 32 ],
        [ 41, 42 ],
        5
      ] )
    end

    it "returns a new Hash copy of the given Hash with hashlike/arraylike contents deeply replaced with deconstructed, symbolized-key copies" do
      result = subject.call( nested_hash )
      expect( result ).to eq( {
        '<shallow_h>' => {'<a>' => 11, '<b>' => 22, 42 => 33 },
        '<shallow_m>' => {'<a>' => 11, '<b>' => 22, 42 => 33 },
        '<array>' => [
          {'<a>' => 11, '<b>' => 22, 42 => 33 },
          {'<a>' => 11, '<b>' => 22, 42 => 33 },
          [ 31, 32 ],
          [ 41, 42 ],
          5
        ],
        42 => 99
      } )
    end

    it "deeply conserves hash entry insertion order" do
      result = subject.call( nested_hash )

      expect( result.keys ).
        to eq( ['<shallow_h>', '<shallow_m>', '<array>', 42 ] )

      expect( result['<array>'].first.keys ).
        to eq( ['<a>', '<b>', 42 ] )
    end
  end

end
