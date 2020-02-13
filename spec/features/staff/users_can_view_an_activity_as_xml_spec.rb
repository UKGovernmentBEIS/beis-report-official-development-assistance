# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Users can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:organisation) { create(:organisation) }

    context "when the user is a fund manager" do
      before { authenticate!(user: create(:fund_manager, organisation: organisation)) }

      context "when the activity is a fund activity" do
        let(:activity) { create(:fund_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains a top-level activities element with the IATI version" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activities/@version").text).to eq(IATI_VERSION.tr("_", "."))
        end

        it "contains the activity XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
          expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)
        end

        it "contains the funding organisation XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation_reference)
          expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation_type)
          expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation_name)
        end

        it "contains the accountable organisation XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
          expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
          expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)
        end

        it "contains the extending organisation XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/participating-org[@role = '3']/@ref").text).to eq(activity.extending_organisation.iati_reference)
          expect(xml.at("iati-activity/participating-org[@role = '3']/@type").text).to eq(activity.extending_organisation.organisation_type)
          expect(xml.at("iati-activity/participating-org[@role = '3']/narrative").text).to eq(activity.extending_organisation.name)
        end

        it "contains the transaction XML" do
          transaction = create(:transaction, activity: activity)
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/transaction/@ref").text).to eq(transaction.reference)
        end

        it "contains the budget XML" do
          budget = create(:budget, activity: activity)
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/budget/@type").text).to eq(budget.budget_type)
          expect(xml.at("iati-activity/budget/@status").text).to eq(budget.status)
          expect(xml.at("iati-activity/budget/value").text).to eq(budget.value.to_s)
          expect(xml.at("iati-activity/budget/period-start/@iso-date").text).to eq(budget.period_start_date.strftime("%Y-%m-%d"))
          expect(xml.at("iati-activity/budget/period-end/@iso-date").text).to eq(budget.period_end_date.strftime("%Y-%m-%d"))
        end
      end

      context "when the activity is a programme activity" do
        let(:activity) { create(:programme_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains the activity XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
          expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)
        end

        it "contains the funding organisation XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation_reference)
          expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation_type)
          expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation_name)
        end

        it "contains the accountable organisation XML" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
          expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
          expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)
        end

        it "contains the budget XML" do
          budget = create(:budget, activity: activity)
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/budget/@type").text).to eq(budget.budget_type)
          expect(xml.at("iati-activity/budget/@status").text).to eq(budget.status)
          expect(xml.at("iati-activity/budget/value").text).to eq(budget.value.to_s)
          expect(xml.at("iati-activity/budget/period-start/@iso-date").text).to eq(budget.period_start_date.strftime("%Y-%m-%d"))
          expect(xml.at("iati-activity/budget/period-end/@iso-date").text).to eq(budget.period_end_date.strftime("%Y-%m-%d"))
        end
      end
    end
  end
end
