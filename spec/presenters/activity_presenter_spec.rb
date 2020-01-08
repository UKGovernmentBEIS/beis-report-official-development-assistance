# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityPresenter do
  let(:activity) { build(:activity) }

  describe "#aid_type" do
    context "when the aid_type exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, aid_type: "a01")
        result = described_class.new(activity).aid_type
        expect(result).to eql("General budget support")
      end

      it "returns the locale value when the code is upper case" do
        activity = build(:activity, aid_type: "A01")
        result = described_class.new(activity).aid_type
        expect(result).to eql("General budget support")
      end
    end

    context "when the activity does not have an aid_type set" do
      it "returns nil" do
        activity = build(:fund_activity, :at_identifier_step)
        result = described_class.new(activity)
        expect(result.aid_type).to be_nil
      end
    end
  end

  describe "#sector" do
    context "when the sector exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, sector: "11110")
        result = described_class.new(activity).sector
        expect(result).to eql("Education policy and administrative management")
      end
    end

    context "when the activity does not have a sector set" do
      it "returns nil" do
        activity = build(:activity, sector: nil)
        result = described_class.new(activity)
        expect(result.sector).to be_nil
      end
    end
  end

  describe "#status" do
    context "when the status exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, status: "2")
        result = described_class.new(activity).status
        expect(result).to eql("Implementation")
      end
    end

    context "when the activity does not have a status set" do
      it "returns nil" do
        activity = build(:activity, status: nil)
        result = described_class.new(activity)
        expect(result.status).to be_nil
      end
    end
  end

  describe "#recipient_region" do
    context "when the aid_type recipient_region" do
      it "returns the locale value for the code" do
        activity = build(:activity, recipient_region: "489")
        result = described_class.new(activity).recipient_region
        expect(result).to eql("South America, regional")
      end
    end

    context "when the activity does not have a recipient_region set" do
      it "returns nil" do
        activity = build(:activity, recipient_region: nil)
        result = described_class.new(activity)
        expect(result.recipient_region).to be_nil
      end
    end
  end

  describe "#flow" do
    context "when flow aid_type exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, flow: "20")
        result = described_class.new(activity).flow
        expect(result).to eql("OOF")
      end
    end

    context "when the activity does not have a flow set" do
      it "returns nil" do
        activity = build(:activity, flow: nil)
        result = described_class.new(activity)
        expect(result.flow).to be_nil
      end
    end
  end

  describe "#finance" do
    context "when the finance exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, finance: "111")
        result = described_class.new(activity).finance
        expect(result).to eql("Subsidies to national private investors")
      end
    end

    context "when the activity does not have a finance set" do
      it "returns nil" do
        activity = build(:activity, finance: nil)
        result = described_class.new(activity)
        expect(result.finance).to be_nil
      end
    end
  end

  describe "#tied_status" do
    context "when the tied_status exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, tied_status: "3")
        result = described_class.new(activity).tied_status
        expect(result).to eql("Partially tied")
      end
    end

    context "when the activity does not have a tied_status set" do
      it "returns nil" do
        activity = build(:activity, tied_status: nil)
        result = described_class.new(activity)
        expect(result.tied_status).to be_nil
      end
    end
  end

  describe "#call_to_action" do
    it "returns 'edit' if the desired attribute is present" do
      activity = build(:activity, title: "My title")
      expect(described_class.new(activity).call_to_action(:title)).to eql("edit")
    end

    it "returns 'add' if the desired attribute is not present" do
      activity = build(:activity, title: nil)
      expect(described_class.new(activity).call_to_action(:title)).to eql("add")
    end
  end
end
