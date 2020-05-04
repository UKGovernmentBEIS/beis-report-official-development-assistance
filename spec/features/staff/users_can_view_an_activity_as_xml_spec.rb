# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Users can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:user) { create(:beis_user) }
    let(:organisation) { user.organisation }

    context "when the user belongs to BEIS" do
      before { authenticate!(user: user) }

      context "when the activity has a previous activity identifier" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            identifier: "IND-ENT-IFIER",
            previous_identifier: "PREV-IND-ENT-IFIER")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "shows the previous identifier as the actvitiy identifier" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.previous_identifier)
        end

        it "shows the activity identifier as the other identifier" do
          iati_identifier = ActivityXmlPresenter.new(activity).iati_identifier

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/other-identifier/@ref").text).to eq(iati_identifier)
        end
      end

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

      context "when the activity does not have actual dates (optional dates)" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            identifier: "IND-ENT-IFIER",
            actual_start_date: nil,
            actual_end_date: nil)
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "does not include empty optional dates" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          optional_start_date = xml.at("iati-activity/activity-date[@type = '2']")
          optional_end_date = xml.at("iati-activity/activity-date[@type = '4']")

          expect(optional_start_date).to be_nil
          expect(optional_end_date).to be_nil
        end
      end

      context "when the activity is a fund activity" do
        let(:activity) { create(:fund_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end

      context "when the activity is a programme activity" do
        let(:activity) { create(:programme_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end

      context "when the activity is a project" do
        let(:activity) { create(:project_activity) }
        let(:fund) { create(:fund_activity) }
        let(:programme) { create(:programme_activity) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "includes its parent activity in the related-activity field" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/related-activity").count).to eq(2)
          expect(xml.at("iati-activity/related-activity/@type").text).to eq("1")
        end
      end

      context "when the activity is a project activity" do
        let(:activity) { create(:project_activity_with_implementing_organisations, organisation: organisation) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end

      context "when the activity has budgets" do
        let(:activity) { create(:project_activity, organisation: organisation) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "only includes budgets which belong to the activity" do
          _budget = create(:budget, parent_activity: activity)
          _other_budget = create(:budget, parent_activity: create(:activity))

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/budget").count).to eq(1)
        end

        it "has the correct budget XML" do
          _budget = create(:budget, parent_activity: activity)

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/budget/@type").text).to eq("1")
          expect(xml.xpath("//iati-activity/budget/@status").text).to eq("1")
          expect(xml.xpath("//iati-activity/budget/value").text).to eq("110.01")
        end
      end

      context "when the activity has transactions" do
        let(:activity) { create(:project_activity, organisation: organisation) }
        let(:activity_presenter) { ActivityXmlPresenter.new(activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "only includes transactions which belong to the activity" do
          _transaction = create(:transaction, parent_activity: activity)
          _other_transaction = create(:transaction, parent_activity: create(:activity))

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/transaction").count).to eq(1)
        end

        it "has the correct transaction XML" do
          _transaction = create(:transaction, parent_activity: activity)

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/transaction/transaction-type/@code").text).to eq("1")
          expect(xml.xpath("//iati-activity/transaction/value").text).to eq("110.01")
        end
      end
    end
  end
end
