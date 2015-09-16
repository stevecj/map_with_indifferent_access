require 'spec_helper'

module MapWithIndifferentAccess

  shared_examples "a collection wrapper" do
    describe '#tainted?' do
      it "returns false when its inner collection is not tainted" do
        expect( subject.tainted? ).to eq( false )
      end

      it "returns true when its inner collection is tainted" do
        inner_collection.taint
        expect( subject.tainted? ).to eq( true )
      end
    end

    describe '#taint' do
      it "causes its inner collection to be tainted" do
        subject.taint
        expect( inner_collection ).to be_tainted
      end

      it "returns the target/wrapper" do
        expect( subject.taint ).to equal( subject )
      end
    end

    describe '#untaint' do
      before do
        inner_collection.taint
      end

      it "causes its inner collection to be untainted" do
        subject.untaint
        expect( inner_collection ).not_to be_tainted
      end

      it "returns the target/wrapper" do
        expect( subject.untaint ).to equal( subject )
      end
    end

    describe '#untrusted?' do
      it "returns false when its inner collection is trusted" do
        expect( subject.untrusted? ).to eq( false )
      end

      it "returns true when its inner collection is not trusted" do
        inner_collection.untrust
        expect( subject.untrusted? ).to eq( true )
      end
    end

    describe '#untrust' do
      it "causes its inner collection to be untrusted" do
        subject.untrust
        expect( inner_collection ).to be_untrusted
      end

      it "returns the target/warapper" do
        expect( subject.untrust ).to equal( subject )
      end
    end

    describe '#trust' do
      before do
        inner_collection.untrust
      end

      it "causes its inner collection to be trusted" do
        subject.trust
        expect( inner_collection ).not_to be_untrusted
      end

      it "returns the target/warapper" do
        expect( subject.trust ).to equal( subject )
      end
    end

    describe '#freeze' do
      it "freezes the inner collection along with the target/warapper" do
        subject.freeze
        expect( inner_collection ).to be_frozen
      end

      it "returns the target/warapper" do
        expect( subject.freeze ).to equal( subject )
      end
    end

    describe '#_frozen?' do
      it "returns false when neither the target/wrapper nor its inner collection is frozen" do
        expect( subject._frozen? ).to eq( false )
      end

      it "returns false when the target/wrapper is not frozen and its inner collection is frozen" do
        inner_collection.freeze
        expect( subject._frozen? ).to eq( false )
      end

      it "returns true when the target/wrapper is frozen" do
        subject.freeze
        expect( subject._frozen? ).to eq( true )
      end
    end

    describe '#dup' do
      context "with an unfrozen inner collection" do
        it "returns a new wrapper class instance with an unfrozen duplicate of the original's unfrozen inner collection" do
          result = subject.dup
          expect( result ).not_to equal( subject )
          expect( result.inner_collection ).to eq( inner_collection )
          expect( result.inner_collection ).not_to equal( inner_collection )
          expect( result.inner_collection ).not_to be_frozen
        end

        it "returns a new wrapper class instance with an unfrozen duplicate of the original's frozen inner collection" do
          inner_collection.freeze

          result = subject.dup
          expect( result ).not_to equal( subject )
          expect( result.inner_collection ).to eq( inner_collection )
          expect( result.inner_collection ).not_to equal( inner_collection )
          expect( result.inner_collection ).not_to be_frozen
        end
      end
    end

    describe '#clone' do
      context "with an unfrozen inner collection" do
        it "returns a new map with an unfrozen duplicate of the original's unfrozen inner-map hash" do
          result = subject.clone
          expect( result ).not_to equal( subject )
          expect( result.inner_collection ).to eq( inner_collection )
          expect( result.inner_collection ).not_to equal( inner_collection )
          expect( result.inner_collection ).not_to be_frozen
        end

        it "returns a new map with a frozen duplicate of the original's frozen inner-map hash" do
          inner_collection.freeze

          result = subject.clone
          expect( result ).not_to equal( subject )
          expect( result.inner_collection ).to eq( inner_collection )
          expect( result.inner_collection ).not_to equal( inner_collection )
          expect( result.inner_collection ).to be_frozen
        end
      end
    end
  end

end
