RSpec.describe FieldInference do
  subject { described_class.new }
  let(:activity) { build(:project_activity) }

  describe "when one field fixes the value of another" do
    before do
      activity.collaboration_type = "3"
      subject.on(:aid_type, "B02").fix(:collaboration_type, "2")
    end

    describe "when a matching value is assigned" do
      before do
        subject.assign(activity, :aid_type, "B02")
      end

      it "sets the value of the source field" do
        expect(activity.aid_type).to eq("B02")
      end

      it "fixes the value of the dependent field" do
        expect(activity.collaboration_type).to eq("2")
      end

      it "does not allow edits to the dependent field" do
        expect(subject).not_to be_editable(activity, :collaboration_type)
      end
    end

    describe "when a non-matching value is assigned" do
      before do
        subject.assign(activity, :aid_type, "C01")
      end

      it "sets the value of the source field" do
        expect(activity.aid_type).to eq("C01")
      end

      it "does not change the dependent field" do
        expect(activity.collaboration_type).to eq("3")
      end

      it "allows edits to the dependent field" do
        expect(subject).to be_editable(activity, :collaboration_type)
      end
    end
  end

  describe "when two fields fix the value of another" do
    before do
      activity.aid_type = nil
      activity.collaboration_type = nil
      activity.fstc_applies = nil

      subject.on(:aid_type, "B01").fix(:fstc_applies, false)
      subject.on(:collaboration_type, "2").fix(:fstc_applies, true)
    end

    it "allows one matching value to be assigned" do
      subject.assign(activity, :aid_type, "B01")
      expect(activity.fstc_applies).to eq(false)
    end

    it "blocks two matching fields from setting different values of the dependent" do
      subject.assign(activity, :aid_type, "B01")

      expect { subject.assign(activity, :collaboration_type, "2") }.to raise_error(
        FieldInference::Conflict,
        'Cannot set `collaboration_type` to "2": ' \
        "would change the value of `fstc_applies` which is fixed to false " \
        'because `aid_type` is "B01"'
      )
    end
  end

  describe "when one field change cascades into another" do
    before do
      activity.aid_type = "C01"
      activity.collaboration_type = "3"
      activity.channel_of_delivery_code = "51000"

      subject.on(:aid_type, "B02").fix(:collaboration_type, "2")
      subject.on(:collaboration_type, "2").fix(:channel_of_delivery_code, "40000")
    end

    describe "when a matching value is set" do
      before do
        subject.assign(activity, :aid_type, "B02")
      end

      it "sets the value of the source field" do
        expect(activity.aid_type).to eq("B02")
      end

      it "fixes the value of the immediately dependent field" do
        expect(activity.collaboration_type).to eq("2")
      end

      it "fixes the value of the descendant field" do
        expect(activity.channel_of_delivery_code).to eq("40000")
      end

      it "does not allow edits to any downstream field" do
        expect(subject).not_to be_editable(activity, :collaboration_type)
        expect(subject).not_to be_editable(activity, :channel_of_delivery_code)
      end
    end

    describe "when a matching value is set further down the chain" do
      before do
        subject.assign(activity, :collaboration_type, "2")
      end

      it "sets the value of the source field" do
        expect(activity.collaboration_type).to eq("2")
      end

      it "does not change the value of the parent field" do
        expect(activity.aid_type).to eq("C01")
      end

      it "fixes the value of the descendant field" do
        expect(activity.channel_of_delivery_code).to eq("40000")
      end

      it "allows edits to the source field" do
        expect(subject).to be_editable(activity, :collaboration_type)
      end

      it "does not allow edits to the dependent field" do
        expect(subject).not_to be_editable(activity, :channel_of_delivery_code)
      end
    end
  end

  describe "when one field restricts the value of another" do
    before do
      activity.collaboration_type = "3"
      subject.on(:aid_type, "B02").restrict(:collaboration_type, ["1", "2"])
    end

    describe "when a matching value is assigned" do
      before do
        subject.assign(activity, :aid_type, "B02")
      end

      it "sets the value of the source field" do
        expect(activity.aid_type).to eq("B02")
      end

      it "does not change the dependent field" do
        expect(activity.collaboration_type).to eq("3")
      end

      it "allows edits to the dependent field" do
        expect(subject).to be_editable(activity, :collaboration_type)
      end

      it "restricts the allowed values for the dependent field" do
        expect(subject.allowed_values(activity, :collaboration_type)).to eq ["1", "2"]
      end
    end

    describe "when a non-matching value is assigned" do
      before do
        subject.assign(activity, :aid_type, "C01")
      end

      it "sets the value of the source field" do
        expect(activity.aid_type).to eq("C01")
      end

      it "does not change the dependent field" do
        expect(activity.collaboration_type).to eq("3")
      end

      it "allows edits to the dependent field" do
        expect(subject).to be_editable(activity, :collaboration_type)
      end

      it "does not restrict the allowed values for the dependent field" do
        expect(subject.allowed_values(activity, :collaboration_type)).to be_nil
      end
    end
  end
end
