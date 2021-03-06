require 'rails_helper'

RSpec.describe Parliament, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:dissolution_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:dissolution_message).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "singleton methods" do
    let(:parliament) { Parliament.create! }
    let(:now) { Time.current }

    before do
      allow(Parliament).to receive(:last_or_create).and_return(parliament)
    end

    after do
      Parliament.reload
    end

    it "delegates dissolution_at to the instance" do
      expect(parliament).to receive(:dissolution_at).and_return(now)
      expect(Parliament.dissolution_at).to eq(now)
    end

    it "delegates dissolution_message to the instance" do
      expect(parliament).to receive(:dissolution_message).and_return("Parliament is dissolving")
      expect(Parliament.dissolution_message).to eq("Parliament is dissolving")
    end

    it "delegates dissolution_announced? to the instance" do
      expect(parliament).to receive(:dissolution_announced?).and_return(true)
      expect(Parliament.dissolution_announced?).to eq(true)
    end

    it "delegates dissolved? to the instance" do
      expect(parliament).to receive(:dissolved?).and_return(true)
      expect(Parliament.dissolved?).to eq(true)
    end
  end

  describe ".reload" do
    let(:parliament) { Parliament.create! }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = parliament
      end

      it "clears the cached instance in Thread.current" do
        expect{ Parliament.reload }.to change {
          Thread.current[:__parliament__]
        }.from(parliament).to(nil)
      end
    end
  end

  describe ".instance" do
    let(:parliament) { Parliament.create! }

    context "when it isn't cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = nil
      end

      after do
        Parliament.reload
      end

      it "finds the last record" do
        expect(Parliament).to receive(:last_or_create).and_return(parliament)
        expect(Parliament.instance).to equal(parliament)
      end

      it "caches it in Thread.current" do
        expect(Parliament).to receive(:last_or_create).and_return(parliament)
        expect(Parliament.instance).to equal(Thread.current[:__parliament__])
      end
    end

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = parliament
      end

      after do
        Parliament.reload
      end

      it "returns the cached instance" do
        expect(Parliament).not_to receive(:last_or_create)
        expect(Parliament.instance).to equal(parliament)
      end
    end
  end

  describe ".before_remove_const" do
    let(:parliament) { Parliament.create! }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = parliament
      end

      it "clears the cached instance in Thread.current" do
        expect{ Parliament.before_remove_const }.to change {
          Thread.current[:__parliament__]
        }.from(parliament).to(nil)
      end
    end
  end

  describe "#dissolution_announced?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        Parliament.create!(dissolution_at: nil)
      end

      it "returns false" do
        expect(parliament.dissolution_announced?).to eq(false)
      end
    end

    context "when dissolution_at is not nil" do
      subject :parliament do
        Parliament.create!(dissolution_at: 2.weeks.from_now)
      end

      it "returns true" do
        expect(parliament.dissolution_announced?).to eq(true)
      end
    end
  end

  describe "#dissolved?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        Parliament.create!(dissolution_at: nil)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(false)
      end
    end

    context "when dissolution_at is in the future" do
      subject :parliament do
        Parliament.create!(dissolution_at: 2.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(false)
      end
    end

    context "when dissolution_at is in the past" do
      subject :parliament do
        Parliament.create!(dissolution_at: 2.weeks.ago)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(true)
      end
    end
  end
end
