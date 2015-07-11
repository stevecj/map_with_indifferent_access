require 'spec_helper'

describe MapWithIndifferentAccess do
  it 'has a version number' do
    expect(MapWithIndifferentAccess::VERSION).not_to be nil
  end

  it "can be converted from an instance of its class, returning the given map" do
    map = described_class::try_convert( subject )
    expect( map ).to equal( subject )
  end

  it "can be converted from a hash, wrapping the given hash" do
    hash = {}

    map = described_class::try_convert( hash )

    expect( map ).to be_kind_of( described_class)
    expect( map.inner_map ).to equal( hash )
  end

  it "cannot be converted from an arbitrary object" do
    expect( described_class::try_convert( nil ) ).to be_nil
    expect( described_class::try_convert( 1   ) ).to be_nil
    expect( described_class::try_convert( []  ) ).to be_nil
  end

  context "an instance constructed with no arguments" do
    it "Allows indexed read/write access to values" do
      subject[  1  ] = 'one'
      subject[ 'a' ] = 'A'
      subject[ :b  ] = 'B'
      expect( subject[  1  ] ).to eq( 'one' )
      expect( subject[ 'a' ] ).to eq( 'A'   )
      expect( subject[ :b  ] ).to eq( 'B'   )
    end

    it "treats string and symbol keys interchangeably" do
      subject[ 'a' ] = 'A'
      subject[ :b  ] = 'B'
      expect( subject[ :a  ] ).to eq( 'A' )
      expect( subject[ 'b' ] ).to eq( 'B' )
    end

    it "provides Hash-like #fetch behavior with key symbol/string indifference" do
      subject[  1  ] = 'one'
      subject[ 'a' ] = 'A'
      subject[ :b  ] = 'B'
      expect( subject.fetch(  1  ) ).to eq( 'one' )
      expect( subject.fetch( :a  ) ).to eq( 'A'   )
      expect( subject.fetch( 'b' ) ).to eq( 'B'   )

      expect{ subject.fetch('x') }.to raise_exception( KeyError )
      expect( subject.fetch('x') { '-' } ).to eq( '-' )
      expect( subject.fetch('x', '#') ).to eq( '#' )
    end

    it "provides its length/size" do
      subject[  1  ] = 'one'
      subject[ 'a' ] = 'A'
      expect( subject.length ).to eq( 2 )
      expect( subject.size   ).to eq( 2 )
    end

    it "enumerates keys in order added" do
      subject[  1     ] = 1
      subject[ 'two'  ] = 2
      subject[ :three ] = 3

      keys = []
      subject.each_key do |key| ; keys << key ; end
      expect( keys ).to eq( [1, 'two', :three] )
    end

    it "has unequal instances via #== with key-symbol-string-indifferently unequal entry sets" do
      subject[  1     ] = 1
      subject[ 'two'  ] = [ {a: 4} ]
      subject[ :three ] = 3

      other = described_class.new
      other[ 'three' ] = 3
      other[ :two    ] = [ {a: :fore} ]
      other[  1      ] = 1

      expect( subject == other ).to eq( false )
    end

    it "has equal instances via #== with key-symbol-string-indifferently equal entry sets" do
      subject[  1     ] = 1
      subject[ 'two'  ] = 2
      subject[ :three ] = 3

      other = described_class.new
      other[ 'three' ] = 3
      other[ :two    ] = 2
      other[  1      ] = 1

      expect( subject == other ).to eq( true )
    end

    it "is enumerable over key/value pairs" do
      subject[  1     ] = 1
      subject[ 'two'  ] = { a: 1 }
      subject[ :three ] = [ 9 ]

      entries = []
      subject.each do |entry| ; entries << entry ; end

      expect( entries ).to eq( [
        [  1,     1 ],
        [ 'two',  described_class.new(a: 1) ],
        [ :three, described_class::Array.new([9]) ]
      ] )

      expect( subject.entries ).to eq( entries )
    end
  end

  context "An instance constructed with an existing Hash" do
    subject { described_class.new(hash) }
    let( :hash ) { {} }

    it "reflects later changes made to the existing hash" do
      hash[ :foo ] = 123
      expect( subject['foo'] ).to eq( 123 )
    end

    it "reflects later changes back to the existing hash" do
      subject[ :abc ] = 'ABC'
      expect( hash[:abc] ).to eq('ABC')
    end

    it "reflects hash-type values from the existing hash as wrapped" do
      h = {}
      hash[:aaa] = h
      expect( subject[:aaa] ).to be_kind_of( described_class )
      expect( subject[:aaa].inner_map ).to equal( h )
    end

    it "reflects array-type values from the existing hash as wrapped" do
      ary = []
      hash[:bbb] = ary
      expect( subject[:bbb] ).to be_kind_of( described_class::Array )
      expect( subject[:bbb].inner_array ).to equal( ary )
    end

    it "modifies the existing underlying entry with string/symbol indifference" do
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
