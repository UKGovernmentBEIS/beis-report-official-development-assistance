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
            delivery_partner_identifier: "IND-ENT-IFIER",
            previous_identifier: "PREV-IND-ENT-IFIER",
            transparency_identifier: "GB-GOV-13-IND-ENT-IFIER")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "shows the previous identifier as the activity identifier" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.previous_identifier)
        end

        it "shows the activity transparency identifier as the other identifier" do
          iati_identifier = activity.transparency_identifier

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/other-identifier/@ref").text).to eq(iati_identifier)
        end
      end

      context "when the activity has recipient_region geography" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            delivery_partner_identifier: "IND-ENT-IFIER",
            geography: :recipient_region,
            recipient_region: "489")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains the recipient region code and fixed vocabulary code of 1" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-region/@code").text).to eq(activity.recipient_region)
          expect(xml.at("iati-activity/recipient-region/@vocabulary").text).to eq("1")
        end

        it "contains the recipient region name as a narrative element" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-region/narrative").text).to eq("South America, regional")
        end
      end

      context "when the activity has recipient_country geography" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            delivery_partner_identifier: "IND-ENT-IFIER",
            geography: :recipient_country,
            recipient_country: "CV")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains the recipient country code and fixed vocabulary code of 1" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-country/@code").text).to eq(activity.recipient_country)
        end

        it "contains the recipient country name as a narrative element" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-country/narrative").text).to eq("Cabo Verde")
        end
      end

      context "when the activity has both recipient_country and recipient_region geography" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            delivery_partner_identifier: "IND-ENT-IFIER",
            geography: :recipient_country,
            recipient_country: "CL",
            recipient_region: "489")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains only the recipient country code" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.at("iati-activity/recipient-country/@code").text).to eq(activity.recipient_country)
          expect(xml.at("iati-activity/recipient-region")).to be_nil
        end
      end

      context "when the activity does not have actual dates (optional dates)" do
        let(:activity) {
          create(:fund_activity,
            organisation: organisation,
            delivery_partner_identifier: "IND-ENT-IFIER",
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

      context "when the activity has a collaboration_type" do
        let(:activity) { create(:programme_activity, organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER", collaboration_type: "1") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "contains the relevant collaboration_type code" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/collaboration-type/@code").text).to eq "1"
        end
      end

      context "when the activity has policy markers" do
        let(:activity) {
          create(:project_activity,
            organisation: organisation,
            delivery_partner_identifier: "IND-ENT-IFIER",
            policy_marker_gender: "not_targeted",
            policy_marker_biodiversity: "significant_objective",
            policy_marker_disability: "principal_objective",
            policy_marker_desertification: "principal_objective_and_in_support",
            policy_marker_nutrition: "not_assessed",
            policy_marker_climate_change_adaptation: "not_assessed",
            policy_marker_climate_change_mitigation: "not_assessed",
            policy_marker_disaster_risk_reduction: "not_assessed")
        }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "includes all the policy markers with reportable values for IATI" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml).to have_selector("iati-activity/policy-marker/@code", count: 4) # We do not report 'not_assessed' values to IATI
        end

        it "includes policy marker for gender with all the correct values" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/policy-marker/@vocabulary").text).to eq("1")
          expect(xml.at("iati-activity/policy-marker/@code").text).to eq("1")
          expect(xml.at("iati-activity/policy-marker/@significance").text).to eq("0")
        end

        it "does not include the policy markers with a value of 'not assessed'" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          significances = xml.xpath("//iati-activity/policy-marker/@significance").to_a
          significances.each do |node|
            expect(node).to_not have_content("1000")
          end
        end
      end

      context "when the activity is Covid19-related" do
        let(:activity) { create(:programme_activity, organisation: organisation, delivery_partner_identifier: "ID-ENT-IFIER", covid19_related: "1") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "appends 'COVID-19' to the activity description" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml.at("iati-activity/description/narrative").text).to end_with "COVID-19"
        end
      end

      context "when the activity is a fund activity" do
        let(:activity) { create(:fund_activity, :with_transparency_identifier, organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"

        it "does not include collaboration_type field" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml).not_to have_selector("iati-activity/collaboration-type")
        end
      end

      context "when the activity is a programme activity" do
        let(:activity) { create(:programme_activity, :with_transparency_identifier, organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"

        it "includes the activity aims/objectives" do
          visit organisation_activity_path(organisation, activity, format: :xml)
          expect(xml).to have_selector("iati-activity/description", count: 2)
          descriptions = xml.xpath("//iati-activity/description/@type").to_a
          expect(descriptions.last.value).to eq("2")
        end
      end

      context "when the activity is a project" do
        let(:activity) { create(:project_activity) }
        let(:fund) { create(:fund_activity) }
        let(:programme) { create(:programme_activity) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "includes its parent activity in the related-activity field" do
          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/related-activity").count).to eq(2)
          expect(xml.at("iati-activity/related-activity/@type").text).to eq("1")
        end
      end

      context "when the activity is a project activity" do
        let(:activity) { create(:project_activity_with_implementing_organisations, :with_transparency_identifier, organisation: organisation) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end

      context "when the activity has budgets" do
        let(:activity) { create(:project_activity, organisation: organisation) }
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

      context "when the activity has planned disbursements" do
        let(:activity) { create(:project_activity, organisation: organisation) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it "only includes planned disbursements which belong to the activity" do
          _planned_disbursement = create(:planned_disbursement, parent_activity: activity)
          _other_planned_disbursement = create(:planned_disbursement, parent_activity: create(:activity))

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/planned-disbursement").count).to eq(1)
        end

        it "has the period end date when one is supplied" do
          planned_disbursement = create(:planned_disbursement, parent_activity: activity, period_start_date: Date.today, period_end_date: Date.today + 3.months)
          planned_disbursement_presenter = PlannedDisbursementXmlPresenter.new(planned_disbursement)

          visit organisation_activity_path(organisation, activity, format: :xml)

          expect(xml.xpath("//iati-activity/planned-disbursement/period-start/@iso-date").text).to eq planned_disbursement_presenter.period_start_date
          expect(xml.xpath("//iati-activity/planned-disbursement/period-end/@iso-date").text).to eq planned_disbursement_presenter.period_end_date
        end

        context "when the planned disbursment receiving organisation type is 0" do
          it "does not output attributes on the receiving organisation element" do
            _planned_disbursement = create(:planned_disbursement, parent_activity: activity, receiving_organisation_type: "0")

            visit organisation_activity_path(organisation, activity, format: :xml)

            expect(xml.xpath("//iati-activity/planned-disbursement/receiver-org/@type")).to be_empty
            expect(xml.xpath("//iati-activity/planned-disbursement/receiver-org/@ref")).to be_empty
            expect(xml.xpath("//iati-activity/planned-disbursement/receiver-org/@receiver-activity-id")).to be_empty
          end
        end
      end
    end
  end
end
