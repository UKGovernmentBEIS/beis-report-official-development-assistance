RSpec.feature "Users can view an organisation as XML" do
  let(:user) { create(:beis_user) }
  let(:organisation) { create(:delivery_partner_organisation) }

  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }

    context "when the user is viewing any organisation show page" do
      scenario "they can download the XML of the organisation" do
        visit organisation_path(organisation)

        expect(page).to have_content(organisation.name)
        expect(page).to have_content(I18n.t("generic.button.download_as_xml"))
      end

      context "whe organisation has projects" do
        scenario "the XML file contains an `iati-activity` element for the project activities in the organisation" do
          project = create(:project_activity, organisation: organisation)

          visit organisation_path(organisation, format: :xml)
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq 1
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to eq project.title
        end
      end

      context "the organisation has third-party projects" do
        scenario "the XML file contains an `iati-activity` element for the third-party project activity in the organisation" do
          project = create(:project_activity, organisation: organisation)
          third_party_project = create(:third_party_project_activity, organisation: organisation)

          visit organisation_path(organisation, format: :xml)
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq 1
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to eq third_party_project.title
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to_not eq project.title
        end
      end

      scenario "the XML file does not contain fund or programme activities in the organisation" do
        _fund = create(:fund_activity, organisation: organisation)
        _programme = create(:programme_activity, extending_organisation: organisation)

        visit organisation_path(organisation, format: :xml)
        xml = Nokogiri::XML::Document.parse(page.body)

        expect(xml.xpath("/iati-activities/iati-activity").count).to eq 0
      end

      scenario "the XML file contains budgets and transactions for activities in the organisation" do
        project = create(:project_activity, organisation: organisation)
        _budget = create(:budget, parent_activity: project, value: 2000)
        _transaction = create(:transaction, parent_activity: project, value: 100)

        visit organisation_path(organisation, format: :xml)
        xml = Nokogiri::XML::Document.parse(page.body)

        expect(xml.xpath("/iati-activities/iati-activity/budget/value").text).to eq "2000.0"
        expect(xml.xpath("/iati-activities/iati-activity/transaction/value").text).to eq "100.0"
      end
    end
  end

  context "when the user does not belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    context "when the user is viewing their own organisaton" do
      let(:organisation) { user.organisation }

      scenario "they cannot download the XML of the organisation" do
        visit organisation_path(organisation)

        expect(page).to have_content(organisation.name)
        expect(page).to_not have_content(I18n.t("generic.button.download_as_xml"))
      end
    end

    context "when the user is viewing another organisaton" do
      let(:organisation) { create(:delivery_partner_organisation) }

      scenario "they cannot download the XML of the organisation" do
        visit organisation_path(organisation, format: :xml)

        expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
      end
    end
  end
end
