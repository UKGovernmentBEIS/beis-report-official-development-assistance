# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Fund managers can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:beis) { create(:beis_organisation) }
    let(:delivery_partner) { create(:organisation) }

    before { authenticate!(user: create(:fund_manager, organisation: beis)) }

    context "when the activity is a fund activity" do
      let(:activity) { create(:fund_activity, organisation: beis, identifier: "IND-ENT-IFIER") }
      let!(:transaction) { create(:transaction, activity: activity) }
      let(:xml) { Nokogiri::XML::Document.parse(page.body) }

      it "contains a top-level activities element with the IATI version" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activities/@version").text).to eq(IATI_VERSION.tr("_", "."))
      end

      it "contains the activity XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
        expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)
      end

      it "contains the funding organisation XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation_name)
      end

      it "contains the accountable organisatinon XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)
      end

      it "contains the extending organisation XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/participating-org[@role = '3']/@ref").text).to eq(activity.extending_organisation.iati_reference)
        expect(xml.at("iati-activity/participating-org[@role = '3']/@type").text).to eq(activity.extending_organisation.organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '3']/narrative").text).to eq(activity.extending_organisation.name)
      end

      it "contains the transaction XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/transaction/@ref").text).to eq(transaction.reference)
      end
    end

    context "when the activity is a programme activity" do
      let(:activity) { create(:programme_activity, organisation: beis, identifier: "IND-ENT-IFIER", extending_organisation: delivery_partner) }
      let(:xml) { Nokogiri::XML::Document.parse(page.body) }

      it "contains the activity XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
        expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)
      end

      it "contains the funding organisation XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation_name)
      end

      it "contains the accountable organisation XML" do
        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)
      end

      it "contains the extending organisation XML" do
        delivery_partner = create(:organisation)
        activity.update(extending_organisation: delivery_partner)

        visit organisation_activity_path(beis, activity, format: :xml)
        expect(xml.at("iati-activity/participating-org[@role = '3']/@ref").text).to eq(delivery_partner.iati_reference)
        expect(xml.at("iati-activity/participating-org[@role = '3']/@type").text).to eq(delivery_partner.organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '3']/narrative").text).to eq(delivery_partner.name)
      end
    end
  end
end
