RSpec.feature "Users can view an organisation as XML" do
  let(:user) { create(:beis_user) }
  let!(:organisation) { create(:delivery_partner_organisation) }

  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }

    context "when the user is viewing an organisation's export page" do
      context "when the organisation has projects" do
        let!(:gcrf_project) { create(:project_activity, :gcrf_funded, organisation: organisation) }
        let!(:newton_project) { create(:project_activity, :newton_funded, organisation: organisation) }
        let!(:redacted_newton_project) { create(:project_activity, :newton_funded, organisation: organisation, publish_to_iati: false) }

        scenario "they can download the projects as xml" do
          visit exports_organisation_path(organisation)

          download = Iati::XmlDownload.new(organisation: organisation, fund: Fund.by_short_name("NF"), level: "project")

          click_link "Download #{download.title}"

          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq 1
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to eq newton_project.title
        end
      end

      context "the organisation has third-party projects" do
        let!(:gcrf_project) { create(:third_party_project_activity, :gcrf_funded, organisation: organisation) }
        let!(:newton_project) { create(:third_party_project_activity, :newton_funded, organisation: organisation) }
        let!(:redacted_newton_project) { create(:third_party_project_activity, :newton_funded, organisation: organisation, publish_to_iati: false) }

        scenario "they can download the organisation's third-party projects as XML" do
          visit exports_organisation_path(organisation)

          download = Iati::XmlDownload.new(organisation: organisation, fund: Fund.by_short_name("NF"), level: "third_party_project")

          click_link "Download #{download.title}"

          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("/iati-activities/iati-activity").count).to eq 1
          expect(xml.xpath("/iati-activities/iati-activity/title/narrative").text).to eq newton_project.title
        end
      end

      scenario "the XML file contains budgets and transactions for activities in the organisation" do
        project = create(:project_activity, :newton_funded, organisation: organisation)
        _budget = create(:budget, parent_activity: project, value: 2000)
        _transaction = create(:transaction, parent_activity: project, value: 100)

        visit exports_organisation_path(organisation)

        download = Iati::XmlDownload.new(organisation: organisation, fund: Fund.by_short_name("NF"), level: "project")

        click_link "Download #{download.title}"

        xml = Nokogiri::XML::Document.parse(page.body)

        expect(xml.xpath("/iati-activities/iati-activity/budget/value").text).to eq "2000.0"
        expect(xml.xpath("/iati-activities/iati-activity/transaction/value").text).to eq "100.0"
      end

      scenario "the XML file does not contain incomplete activities" do
        _complete_project = create(:project_activity, :newton_funded, organisation: organisation)
        _project = create(:project_activity, :newton_funded, :at_purpose_step, organisation: organisation)

        visit exports_organisation_path(organisation)

        download = Iati::XmlDownload.new(organisation: organisation, fund: Fund.by_short_name("NF"), level: "project")

        click_link "Download #{download.title}"

        xml = Nokogiri::XML::Document.parse(page.body)

        expect(xml.xpath("/iati-activities/iati-activity").count).to eq(1)
      end

      context "when downloading programme level activities" do
        def forecast(activity, year, quarter)
          ForecastHistory.new(activity, financial_year: year, financial_quarter: quarter)
        end

        it "sums up the total forecasts of all the programmes and their child activities by quarter" do
          programme = create(:programme_activity, :newton_funded, extending_organisation: organisation)

          project_1 = create(:project_activity, parent: programme, organisation: organisation)
          third_party_project_1 = create(:third_party_project_activity, parent: project_1, organisation: organisation)
          _third_party_project_2 = create(:third_party_project_activity, parent: project_1, organisation: organisation)

          project_2 = create(:project_activity, parent: programme, organisation: organisation)
          third_party_project_3 = create(:third_party_project_activity, parent: project_2, organisation: organisation)
          third_party_project_4 = create(:third_party_project_activity, parent: project_2, organisation: organisation)

          ReportingCycle.new(project_1, 2, 2021).tick

          # forecasts for Q3 2021
          forecast(programme, 2021, 3).set_value(10)
          forecast(project_1, 2021, 3).set_value(20)
          forecast(third_party_project_3, 2021, 3).set_value(40)

          # forecasts for Q4 2021
          forecast(project_2, 2021, 4).set_value(80)
          forecast(third_party_project_1, 2021, 4).set_value(160)
          forecast(third_party_project_4, 2021, 4).set_value(320)

          visit iati_programme_activities_exports_organisation_path(organisation, format: :xml, fund: "NF")
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("//iati-activity/planned-disbursement/period-start/@iso-date").map(&:text)).to eql(["2022-01-01", "2021-10-01"])
          expect(xml.xpath("//iati-activity/planned-disbursement/value").map(&:text)).to eql(["560.00", "70.00"])
        end

        it "sums up the total transactions of all the programmes and their child activities by quarter" do
          programme = create(:programme_activity, :newton_funded, :with_transparency_identifier, extending_organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER")
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

          visit iati_programme_activities_exports_organisation_path(organisation, format: :xml, fund: "NF")
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("//iati-activity/transaction/value").map(&:text)).to eql(["3360.0", "20.0", "1690.0", "40.0"])
          expect(xml.xpath("//iati-activity/transaction/transaction-date/@iso-date").map(&:text)).to eql(["2020-06-30", "2018-09-30", "2018-06-30", "2019-12-31"])
        end
      end

      context "when downloading project level activities" do
        it "includes all transactions for those projects only" do
          project = create(:project_activity, :gcrf_funded, :with_transparency_identifier, organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER")
          other_project = create(:project_activity, :gcrf_funded, parent: project.parent, organisation: organisation)

          third_party_project = create(:third_party_project_activity, :gcrf_funded, parent: project)

          create(:transaction, value: 100, parent_activity: project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 150, parent_activity: project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 200, parent_activity: other_project, financial_year: 2019, financial_quarter: 3)

          create(:transaction, value: 99, parent_activity: third_party_project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 77, parent_activity: third_party_project, financial_year: 2020, financial_quarter: 1)

          visit iati_project_activities_exports_organisation_path(organisation, format: :xml, fund: "GCRF")
          xml = Nokogiri::XML::Document.parse(page.body)

          expect(xml.xpath("//iati-activity/transaction/value").map(&:text)).to match_array(["100.0", "150.0", "200.0"])
          expect(xml.xpath("//iati-activity/transaction/transaction-date/@iso-date").map(&:text)).to eql(["2018-06-30", "2018-06-30", "2019-12-31"])
        end
      end
    end
  end
end
