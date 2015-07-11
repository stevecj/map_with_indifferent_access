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
end
