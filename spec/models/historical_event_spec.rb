require "rails_helper"

RSpec.describe HistoricalEvent, type: :model do
  describe "associations" do
    it { should belong_to(:activity) }
    it { should belong_to(:trackable) }
    it { should belong_to(:user) }
    it { should belong_to(:report).optional }
  end

  describe "polymorphic 'trackable' association" do
    context "when the change being tracked is on an Activity" do
      let(:trackable) { create(:project_activity) }
      let(:event) { HistoricalEvent.new(trackable: trackable) }

      it "associates with the expected Activity object" do
        expect(event.trackable_id).to eq(trackable.id)
        expect(event.trackable_type).to eq("Activity")
        expect(event.trackable).to eq(trackable)
      end
    end

    context "when the change being tracked is on an Actual (subclass of Transaction)" do
      let(:trackable) { create(:actual) }
      let(:event) { HistoricalEvent.new(trackable: trackable) }

      it "associates with the expected Actual object" do
        expect(event.trackable_id).to eq(trackable.id)
        expect(event.trackable).to eq(trackable)
      end

      it "correctly sets the subclass at the point of validation" do
        expect { event.valid? }
          .to change { event.trackable_type }
          .from("Transaction")
          .to("Actual")
      end
    end
  end

  describe "flexible 'value' fields which handle a range of data types" do
    let(:event) { HistoricalEvent.new }

    context "when value is a String" do
      let(:persisted_event) do
        set_value_fields_to("String")
      end

      it "should read back a String" do
        expect(persisted_event.new_value).to eq("String")
        expect(persisted_event.previous_value).to eq("String")
      end
    end

    context "when value is an Integer" do
      let(:persisted_event) do
        set_value_fields_to(101)
      end

      it "should read back an Integer" do
        expect(persisted_event.new_value).to eq(101)
        expect(persisted_event.previous_value).to eq(101)
      end
    end

    context "when value is a boolean" do
      let(:persisted_event) do
        set_value_fields_to(true)
      end

      it "should read back an boolean" do
        expect(persisted_event.new_value).to be true
        expect(persisted_event.previous_value).to be true
      end
    end

    context "when value is a datetime" do
      let(:datetime) { Time.current }

      let(:persisted_event) do
        set_value_fields_to(datetime)
      end

      it "should read back a datetime" do
        expect(persisted_event.new_value).to eq(datetime)
        expect(persisted_event.previous_value).to eq(datetime)
      end
    end

    context "when value is a date" do
      let(:date) { Date.parse("01-Jan-2020") }

      let(:persisted_event) do
        set_value_fields_to(date)
      end

      it "should read back a date" do
        expect(persisted_event.new_value).to eq(date)
        expect(persisted_event.previous_value).to eq(date)
      end
    end

    context "when value is a BigDecimal" do
      let(:bigdecimal) { BigDecimal("101.10") }

      let(:persisted_event) do
        set_value_fields_to(bigdecimal)
      end

      it "should read back a bigdecimal" do
        expect(persisted_event.new_value).to eq(bigdecimal)
        expect(persisted_event.previous_value).to eq(bigdecimal)
      end
    end

    def set_value_fields_to(value)
      event.tap do |e|
        e.new_value = value
        e.previous_value = value
      end
    end
  end
end
