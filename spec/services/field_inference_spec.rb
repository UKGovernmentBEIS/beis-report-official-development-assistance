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
end
