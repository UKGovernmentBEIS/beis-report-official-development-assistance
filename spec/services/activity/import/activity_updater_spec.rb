require "rails_helper"

RSpec.describe Activity::Import::ActivityUpdater do
  let(:organisation) { create(:partner_organisation) }
  let(:uploader) { create(:partner_organisation_user, organisation: organisation) }
  let(:fund_activity) { create(:fund_activity) }
  let(:report) { create(:report, fund: fund_activity) }
  let(:existing_activity) { create(:project_activity) }
  let(:updater) { nil }

  let(:row) do
    {
      "RODA ID" => existing_activity.roda_identifier,
      "Transparency identifier" => "13232332323",
      "Parent RODA ID" => "",
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Benefitting Countries" => "KH|KP|ID",
      "Partner organisation identifier" => "1234567890",
      "GDI" => "1",
      "GCRF Strategic Area" => "17A|RF",
      "GCRF Challenge Area" => "4",
      "SDG 1" => "1",
      "SDG 2" => "2",
      "SDG 3" => "3",
      "Covid-19 related research" => "0",
      "ODA Eligibility" => "0",
      "ODA Eligibility Lead" => "Bruce Wayne",
      "Newton Fund Pillar" => "1",
      "Activity Status" => "1",
      "Call open date" => "02/01/2020",
      "Call close date" => "02/01/2020",
      "Total applications" => "12",
      "Total awards" => "12",
      "Planned start date" => "02/01/2020",
      "Actual start date" => "03/01/2020",
      "Planned end date" => "04/01/2020",
      "Actual end date" => "05/01/2020",
      "Sector" => "11220",
      "Channel of delivery code" => "11000",
      "Collaboration type (Bi/Multi Marker)" => "1",
      "DFID policy marker - Gender" => "0",
      "DFID policy marker - Climate Change - Adaptation" => "2",
      "DFID policy marker - Climate Change - Mitigation" => "1",
      "DFID policy marker - Biodiversity" => "2",
      "DFID policy marker - Desertification" => "3",
      "DFID policy marker - Disability" => "",
      "DFID policy marker - Disaster Risk Reduction" => "0",
      "DFID policy marker - Nutrition" => "",
      "Aid type" => "B03",
      "Free Standing Technical Cooperation" => "1",
      "Aims/Objectives" => "Foo bar baz",
      "BEIS ID" => "BEIS_ID_EXAMPLE_01",
      "UK PO Named Contact" => "Jo Soap",
      "NF Partner Country PO" => "Association of Example Companies (AEC) | | Board of Sample Organisations (BSO)",
      "Implementing organisation names" => "Impl. Org 1",
      "Comments" => "Cat"
    }
  end

  let(:activity_policy_double) { instance_double("ActivityPolicy", update?: true) }

  before do
    allow(ActivityPolicy).to receive(:new).and_return(activity_policy_double)
  end

  subject {
    Activity::Import::ActivityUpdater.new(
      row: row,
      uploader: uploader,
      partner_organisation: organisation,
      report: report,
      is_oda: nil
    )
  }

  describe "#initialize" do
    context "when the activity does not exist" do
      before { row["RODA ID"] = "FAKE RODA ID" }

      it "creates an error" do
        expect(subject.errors[:roda_id]).to eq(["FAKE RODA ID", I18n.t("importer.errors.activity.not_found")])
      end
    end
  end
end
