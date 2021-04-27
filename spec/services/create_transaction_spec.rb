require "rails_helper"

RSpec.describe CreateTransaction do
  let!(:service_owner) { create(:beis_organisation) }
  let(:activity) { create(:activity) }

  describe "#call" do
    it "sets the parent activity as the one this transaction belongs to" do
      result = described_class.new(activity: activity).call
      expect(result.object.parent_activity).to eq(activity)
    end

    it "returns a successful result" do
      allow_any_instance_of(Transaction).to receive(:valid?).and_return(true)
      allow_any_instance_of(Transaction).to receive(:save).and_return(true)

      result = described_class.new(activity: activity).call(attributes: {})

      expect(result.success?).to be true
    end

    context "when the transaction isn't valid" do
      it "returns a failed result" do
        allow_any_instance_of(Transaction).to receive(:valid?).and_return(false)

        result = described_class.new(activity: activity).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when the activity belongs to BEIS" do
      it "does not set the report" do
        activity.update(organisation: build_stubbed(:beis_organisation))
        result = described_class.new(activity: activity).call
        expect(result.object.report).to be_nil
      end
    end

    context "when the activity belongs to a delivery partner organisation" do
      it "does set the report" do
        activity.update(organisation: build_stubbed(:delivery_partner_organisation))
        editable_report_for_activity = create(:report, state: :active, organisation: activity.organisation, fund: activity.associated_fund)
        result = described_class.new(activity: activity).call
        expect(result.object.report).to eql editable_report_for_activity
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as transaction attributes" do
        attributes = ActionController::Parameters.new(description: "foo").permit!

        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.description).to eq("foo")
      end

      subject { described_class.new(activity: activity) }
      it_behaves_like "sanitises monetary field"
    end

    context "when the description is blank" do
      it "sets a default description" do
        activity = create(:activity, title: "Some activity")
        attributes = ActionController::Parameters.new(financial_quarter: 1, financial_year: 2020).permit!

        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.description).to eq "FQ1 2020-2021 spend on Some activity"
      end
    end

    context "when the date and description is blank" do
      it "does not set the default description" do
        attributes = ActionController::Parameters.new.permit!
        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.description).to eq nil
      end
    end

    context "when the transaction type is not set" do
      it "sets the default transaction type" do
        attributes = ActionController::Parameters.new.permit!
        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.transaction_type).to eq Transaction::DEFAULT_TRANSACTION_TYPE
      end
    end

    context "when the transaction type is set" do
      it "sets the default transaction type" do
        attributes = ActionController::Parameters.new({transaction_type: 2}).permit!
        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.transaction_type).to eq "2"
      end
    end

    it "sets the providing organisation from the activity" do
      attributes = ActionController::Parameters.new.permit!
      result = described_class.new(activity: activity).call(attributes: attributes)

      expect(result.object.providing_organisation_name).to eq activity.providing_organisation.name
      expect(result.object.providing_organisation_type).to eq activity.providing_organisation.organisation_type
      expect(result.object.providing_organisation_reference).to eq activity.providing_organisation.iati_reference
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { described_class.new(activity: activity).call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end
  end
end
