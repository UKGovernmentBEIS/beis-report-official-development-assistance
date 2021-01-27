RSpec.feature "Users can view an organisation as XML" do
  let(:user) { create(:beis_user) }
  let!(:organisation) { create(:delivery_partner_organisation) }

  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }

    context "when the user is viewing the BEIS organisation show page" do
      scenario "they cannot download the organisation's projects as XML" do
        beis = user.organisation
        _project = create(:project_activity, organisation: beis)

        visit organisation_path(beis)

        expect(page).to have_content(beis.name)
        expect(page).to_not have_content(t("default.button.download_as_xml"))
      end
    end

    context "when the user is viewing any other organisation show page" do
      context "when the organisation has programmes which it is the extending organisation of" do
        scenario "they can see the download xml button for programmes" do
          fund = create(:fund_activity)
          another_fund = create(:fund_activity)
          _programme = create(:programme_activity, parent: fund, extending_organisation: organisation)
          _anohter_programme = create(:programme_activity, parent: another_fund, extending_organisation: organisation)

          visit organisation_path(organisation)

          expect(page).to have_link t("page_content.organisation.download.programmes.button", fund_title: fund.title),
            href: organisation_path(organisation, format: :xml, level: :programme, fund_id: fund.id)
          expect(page).to have_link t("page_content.organisation.download.programmes.button", fund_title: another_fund.title),
            href: organisation_path(organisation, format: :xml, level: :programme, fund_id: another_fund.id)
        end
      end

      context "when the organisation has projects" do
        scenario "they can download the organisation's projects as XML" do
          _project = create(:project_activity, organisation: organisation)

          visit organisation_path(organisation)

          expect(page).to have_content(organisation.name)
          expect(page).to have_content(t("default.button.download_as_xml"))
        end

        scenario "the XML file contains an `iati-activity` element for the project activities in the organisation" do
          project = create(:project_activity, organisation: organisation)

          visit organisation_path(organisation)
          within ".download-projects" do
            click_link t("default.button.download_as_xml")
          end
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq 1
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to eq project.title
        end

        scenario "the XML file does not contain projects which should not be published to IATI" do
          _project = create(:project_activity, organisation: organisation, publish_to_iati: true)
          redacted_project = create(:project_activity, organisation: organisation, publish_to_iati: false)

          visit organisation_path(organisation)
          within ".download-projects" do
            click_link t("default.button.download_as_xml")
          end
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq(1)
          expect(page.body).not_to include redacted_project.title
        end
      end

      context "the organisation has third-party projects" do
        scenario "they can download the organisation's third-party projects as XML" do
          _third_party_project = create(:third_party_project_activity, organisation: organisation)

          visit organisation_path(organisation)

          expect(page).to have_content(organisation.name)
          expect(page).to have_content(t("default.button.download_as_xml"))
        end

        scenario "the XML file contains an `iati-activity` element for the third-party project activity in the organisation" do
          project = create(:project_activity, organisation: organisation)
          third_party_project = create(:third_party_project_activity, organisation: organisation)

          visit organisation_path(organisation)
          within ".download-third-party-projects" do
            click_link t("default.button.download_as_xml")
          end
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq 1
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to eq third_party_project.title
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to_not eq project.title
        end

        scenario "the XML file does not contain third-party projects which should not be published to IATI" do
          _project = create(:third_party_project_activity, organisation: organisation, publish_to_iati: true)
          redacted_project = create(:third_party_project_activity, organisation: organisation, publish_to_iati: false)

          visit organisation_path(organisation)
          within ".download-third-party-projects" do
            click_link t("default.button.download_as_xml")
          end
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq(1)
          expect(page.body).not_to include redacted_project.title
        end
      end

      context "the organisation does not have programmes" do
        scenario "the download button does not appear for programmes" do
          visit organisation_path(organisation)

          expect(page).to have_content(organisation.name)
          expect(page).to_not have_content(t("default.button.download_as_xml"))
        end
      end

      context "the organisation does not have projects" do
        scenario "the download button does not appear for projects" do
          visit organisation_path(organisation)

          expect(page).to have_content(organisation.name)
          expect(page).to_not have_content(t("default.button.download_as_xml"))
        end
      end

      context "the organisation does not have third-party projects" do
        scenario "the download button does not appear for third-party projects" do
          visit organisation_path(organisation)

          expect(page).to have_content(organisation.name)
          expect(page).to_not have_content(t("default.button.download_as_xml"))
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

        visit organisation_path(organisation)
        click_link t("default.button.download_as_xml")
        xml = Nokogiri::XML::Document.parse(page.body)

        expect(xml.xpath("/iati-activities/iati-activity/budget/value").text).to eq "2000.0"
        expect(xml.xpath("/iati-activities/iati-activity/transaction/value").text).to eq "100.0"
      end

      scenario "the XML file does not contain incomplete activities" do
        _complete_project = create(:project_activity, organisation: organisation)
        _project = create(:project_activity, :at_purpose_step, organisation: organisation)
        visit organisation_path(organisation)
        click_link t("default.button.download_as_xml")
        xml = Nokogiri::XML::Document.parse(page.body)

        expect(xml.xpath("/iati-activities/iati-activity").count).to eq(1)
      end
    end
  end

  context "when the user does not belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    context "when the user is viewing their own organisation" do
      let(:organisation) { user.organisation }

      scenario "they cannot download the organisation's activities as XML" do
        _project = create(:project_activity, organisation: organisation)

        visit organisation_path(organisation)

        expect(page).to have_content(organisation.name)
        expect(page).to_not have_content(t("default.button.download_as_xml"))
      end

      scenario "they do not see the programmes download buttons" do
        programme = create(:programme_activity, extending_organisation: organisation)
        _project = create(:project_activity, parent: programme, organisation: organisation)
        fund = programme.parent

        visit organisation_path(organisation)

        expect(page).not_to have_link t("page_content.organisation.download.programmes.button", fund_title: fund.title),
          href: organisation_path(organisation, format: :xml, level: :programme, fund_id: fund.id)
      end
    end

    context "when the user is viewing another organisation" do
      let(:organisation) { create(:delivery_partner_organisation) }

      scenario "they cannot download the XML of the organisation" do
        visit organisation_path(organisation, format: :xml)

        expect(page).to have_content(t("page_title.errors.not_authorised"))
      end
    end
  end
end
