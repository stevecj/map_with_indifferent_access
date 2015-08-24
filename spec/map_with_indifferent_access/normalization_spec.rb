require 'spec_helper'

module NormalizationSpec
  include MapWithIndifferentAccess::WithConveniences

  class HashAnalog  < Struct.new(:to_hash )
    def each_pair ; end
  end

  class ArrayAnalog < Struct.new(:to_ary  )
  end

  describe MWIA::Normalization do
    describe "deeply_symbolize_keys" do
      def build_given_hash
        {
          'a' => 1,
          :b  => {'bb' => 22 },
           3  => [ 33, MWIA.new('cc' => 333 ) ]
        }
      end

      def build_given_array
        [
          1,
          [
            12,
            { 'b2' => {'bb2' => 22 } }
          ]
        ]
      end

      it "returns a copy of a given Hash with inner content deconstructed and keys symbolized deeply" do
        result = subject.deeply_symbolize_keys( build_given_hash )

        expect( result ).to eq( {
          :a   => 1,
          :b   => {:bb => 22 },
          :'3' => [ 33, {:cc => 333 } ]
        } )
      end

      it "does not modfy the contents of the given Hash" do
        given_hash = build_given_hash
        result = subject.deeply_symbolize_keys( build_given_hash )
        expect( given_hash ).to eq( build_given_hash )
      end

      it "returns a copy of a given Array with keys symbolized deeply" do
        result = subject.deeply_symbolize_keys( build_given_array )

        expect( result ).to eq( [
          1,
          [
            12,
            {:b2 => {:bb2 => 22 } }
          ]
        ] )
      end

      it "does not modfy the contents of the given Array" do
        given_array = build_given_array
        result = subject.deeply_symbolize_keys( build_given_array )
        expect( given_array ).to eq( build_given_array )
      end
    end

    describe '#deeply_stringify_keys' do
      def build_given_hash
        {
          'a' => 1,
          :b  => {:bb => 22 },
           3  => [ 33, MWIA.new(:cc => 333 ) ]
        }
      end

      def build_given_array
        [
          1,
          [
            12,
            { :b2 => {:bb2 => 22 } }
          ]
        ]
      end

      it "returns a copy of a given Hash with inner content deconstructed and keys stringified deeply" do
        result = subject.deeply_stringify_keys( build_given_hash )

        expect( result ).to eq( {
          'a' => 1,
          'b' => {'bb' => 22 },
          '3' => [ 33, {'cc' => 333 } ]
        } )
        expect( result.keys ).to eq( ['a', 'b', '3'] )
        expect( result['a'] ).to eq( 1 )
        expect( result['b'] ).to eq( {'bb' => 22 } )
        expect( result['3'] ).to eq( [ 33, 'cc' => 333 ] )
      end

      it "does not modfy the contents of the given Hash" do
        given_hash = build_given_hash
        result = subject.deeply_stringify_keys( build_given_hash )
        expect( given_hash ).to eq( build_given_hash )
      end

      it "returns a copy of a given Array with keys stringified deeply" do
        result = subject.deeply_stringify_keys( build_given_array )

        expect( result ).to eq( [
          1,
          [
            12,
            {'b2' => {'bb2' => 22 } }
          ]
        ] )
      end

      it "does not modfy the contents of the given Array" do
        given_array = build_given_array
        result = subject.deeply_stringify_keys( build_given_array )
        expect( given_array ).to eq( build_given_array )
      end
    end
  end

end
