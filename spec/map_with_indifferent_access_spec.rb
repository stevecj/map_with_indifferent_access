require 'spec_helper'

describe MapWithIndifferentAccess do
  it 'has a version number' do
    expect(MapWithIndifferentAccess::VERSION).not_to be nil
  end

  context "An instance constructed with no arguments" do
    it "Allows indexed read/write access to values" do
      subject[  1  ] = 'one'
      subject[ 'a' ] = 'A'
      subject[ :b  ] = 'B'
      expect( subject[  1  ] ).to eq( 'one' )
      expect( subject[ 'a' ] ).to eq( 'A'   )
      expect( subject[ :b  ] ).to eq( 'B'   )
    end

    it "Treats string and symbol keys interchangeably" do
      subject[ 'a' ] = 'A'
      subject[ :b  ] = 'B'
      expect( subject[ :a  ] ).to eq( 'A' )
      expect( subject[ 'b' ] ).to eq( 'B' )
    end
  end

  context "An instance constructed with an existing Hash" do
    subject { described_class.new(hash) }
    let( :hash ) { {} }

    it "Reflects later changes made to the existing hash" do
      hash[ :foo ] = 123
      expect( subject['foo'] ).to eq( 123 )
    end

    it "Reflects later changes back to the existing hash" do
      subject[ :abc ] = 'ABC'
      expect( hash[:abc] ).to eq('ABC')
    end

    it "Modifies the existing underlying entry with string/symbol indifference" do
      hash[ :aaa  ] = 'A'
      hash[ 'bbb' ] = 'B'
      subject[ 'aaa' ] = 'AA'
      subject[ :bbb  ] = 'BB'

      expect( hash ).to eq( {
        :aaa  => 'AA',
        'bbb' => 'BB'
      } )
    end
  end
end
