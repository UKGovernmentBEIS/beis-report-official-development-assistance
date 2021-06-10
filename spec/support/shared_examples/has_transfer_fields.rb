RSpec.shared_examples "has transfer fields" do |transfer|
  it { should belong_to(:source).class_name("Activity") }
  it { should belong_to(:destination).class_name("Activity") }

  describe "validations" do
    it { should validate_presence_of(:source) }
    it { should validate_presence_of(:destination) }
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:financial_year) }
    it { should validate_presence_of(:financial_quarter) }

    it { should validate_numericality_of(:value).is_less_than_or_equal_to(99_999_999_999.00) }
    it { should validate_numericality_of(:value).is_other_than(0) }
  end

  describe "foreign key constraints" do
    subject { create(:outgoing_transfer) }

    it "prevents the associated source activity from being deleted" do
      source_activity = subject.source

      expect { source_activity.destroy }.to raise_exception(/ForeignKeyViolation/)
    end

    it "prevents the associated destination activity from being deleted" do
      destination_activity = subject.destination

      expect { destination_activity.destroy }.to raise_exception(/ForeignKeyViolation/)
    end
  end
end
