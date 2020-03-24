# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Users can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:user) { create(:beis_user) }
    let(:organisation) { user.organisation }

    context "when the user belongs to BEIS" do
      before { authenticate!(user: user) }

      context "when the activity has recipient_region geography" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            identifier: "IND-ENT-IFIER",
            geography: :recipient_region,
            recipient_region: "489")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains the recipient region code and fixed vocabulary code of 1" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-region/@code").text).to eq(activity.recipient_region)
          expect(xml.at("iati-activity/recipient-region/@vocabulary").text).to eq("1")
        end
      end

      context "when the activity has recipient_country geography" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            identifier: "IND-ENT-IFIER",
            geography: :recipient_country,
            recipient_country: "CL")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains the recipient country code and fixed vocabulary code of 1" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-country/@code").text).to eq(activity.recipient_country)
        end
      end

      context "when the activity is a fund activity" do
        let(:activity) { create(:fund_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"

        it "sets BEIS as the reporting org" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/reporting-org/@type").text).to eq("10")
          expect(xml.at("iati-activity/reporting-org/@ref").text).to eq("GB-GOV-13")
          expect(xml.at("iati-activity/reporting-org/narrative").text).to eq("Department for Business, Energy and Industrial Strategy")
        end
      end

      context "when the activity is a programme activity" do
        let(:activity) { create(:programme_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"

        it "sets BEIS as the reporting org" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/reporting-org/@type").text).to eq("10")
          expect(xml.at("iati-activity/reporting-org/@ref").text).to eq("GB-GOV-13")
          expect(xml.at("iati-activity/reporting-org/narrative").text).to eq("Department for Business, Energy and Industrial Strategy")
        end
      end

      context "when the activity is a project activity" do
        let(:activity) { create(:project_activity_with_implementing_organisations, organisation: organisation) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"

        context "when the delivery partner is a governmental organisation" do
          let(:organisation) { create(:organisation, name: "UKSA", organisation_type: 10) }

          it "sets BEIS as the reporting org" do
            visit organisation_activity_path(organisation, activity, format: :xml)

            expect(xml.at("iati-activity/reporting-org/@type").text).to eq("10")
            expect(xml.at("iati-activity/reporting-org/@ref").text).to eq("GB-GOV-13")
            expect(xml.at("iati-activity/reporting-org/narrative").text).to eq("Department for Business, Energy and Industrial Strategy")
          end
        end

        context "when the delivery partner isa non-governmental organisation" do
          let(:organisation) { create(:organisation, name: "AMS", organisation_type: 15) }

          it "sets itself as the reporting org" do
            visit organisation_activity_path(organisation, activity, format: :xml)

            expect(xml.at("iati-activity/reporting-org/@type").text).to eq(organisation.organisation_type)
            expect(xml.at("iati-activity/reporting-org/@ref").text).to eq(organisation.iati_reference)
            expect(xml.at("iati-activity/reporting-org/narrative").text).to eq(organisation.name)
          end
        end
      end

      context "when the activity has budgets" do
        let(:activity) { create(:project_activity, organisation: organisation) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "only includes budgets which belong to the activity" do
          _budget = create(:budget, activity: activity)
          _other_budget = create(:budget, activity: create(:activity))

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/budget").count).to eq(1)
        end
      end

      context "when the activity has transactions" do
        let(:activity) { create(:project_activity, organisation: organisation) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "only includes transactions which belong to the activity" do
          _transaction = create(:transaction, activity: activity)
          _other_transaction = create(:transaction, activity: create(:activity))

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/transaction").count).to eq(1)
        end
      end
    end
  end
end
