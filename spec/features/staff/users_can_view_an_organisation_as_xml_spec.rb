RSpec.feature "Users can view an organisation as XML" do
  let(:user) { create(:beis_user) }
  let!(:organisation) { create(:delivery_partner_organisation) }

  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }

    context "when the user is viewing the BEIS organisation show page" do
      scenario "they cannot download the organisation's projects as XML" do
        beis = user.organisation
        _programme = create(:programme_activity, organisation: beis)

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
        beis = create(:beis_organisation)
        _fund = create(:fund_activity, organisation: beis)
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

      context "when downloading programme level activities" do
        it "sums up the total transactions of all the programmes and their child activities by quarter" do
          programme = create(:programme_activity, :with_transparency_identifier, extending_organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER")
          other_programme = create(:programme_activity, parent: programme.parent, extending_organisation: organisation)

          activity_projects = create_list(:project_activity, 2, parent: programme)
          activity_third_party_project = create(:third_party_project_activity, parent: activity_projects[0])

          create(:transaction, value: 10, parent_activity: programme, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 20, parent_activity: programme, financial_year: 2018, financial_quarter: 2)
          create(:transaction, value: 40, parent_activity: other_programme, financial_year: 2019, financial_quarter: 3)

          create(:transaction, value: 80, parent_activity: activity_projects[0], financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 160, parent_activity: activity_projects[0], financial_year: 2020, financial_quarter: 1)

          create(:transaction, value: 320, parent_activity: activity_projects[1], financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 640, parent_activity: activity_projects[1], financial_year: 2020, financial_quarter: 1)

          create(:transaction, value: 1280, parent_activity: activity_third_party_project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 2560, parent_activity: activity_third_party_project, financial_year: 2020, financial_quarter: 1)

          visit organisation_path(organisation, format: :xml, level: :programme, fund_id: programme.associated_fund.id)
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("//iati-activity/transaction/value").map(&:text)).to eql(["3360.0", "20.0", "1690.0", "40.0"])
          expect(xml.xpath("//iati-activity/transaction/transaction-date/@iso-date").map(&:text)).to eql(["2020-06-30", "2018-09-30", "2018-06-30", "2019-12-31"])
        end
      end

      context "when downloading project level activities" do
        it "includes all transactions for those projects only" do
          project = create(:project_activity, :with_transparency_identifier, organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER")
          other_project = create(:project_activity, parent: project.parent, organisation: organisation)

          third_party_project = create(:third_party_project_activity, parent: project)

          create(:transaction, value: 100, parent_activity: project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 150, parent_activity: project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 200, parent_activity: other_project, financial_year: 2019, financial_quarter: 3)

          create(:transaction, value: 99, parent_activity: third_party_project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 77, parent_activity: third_party_project, financial_year: 2020, financial_quarter: 1)

          visit organisation_path(organisation, format: :xml, level: :project)
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("//iati-activity/transaction/value").map(&:text)).to match_array(["100.0", "150.0", "200.0"])
          expect(xml.xpath("//iati-activity/transaction/transaction-date/@iso-date").map(&:text)).to eql(["2018-06-30", "2018-06-30", "2019-12-31"])
        end
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
