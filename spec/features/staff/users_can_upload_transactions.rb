RSpec.feature "users can upload transactions" do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }

  let!(:project) { create(:project_activity, organisation: organisation) }
  let!(:sibling_project) { create(:project_activity, organisation: organisation, parent: project.parent) }
  let!(:cousin_project) { create(:project_activity, organisation: organisation) }

  let! :report do
    create(:report,
      state: :active,
      fund: project.associated_fund,
      organisation: organisation)
  end

  before do
    authenticate!(user: user)
    visit report_path(report)
    click_link t("action.transaction.upload.link")
  end

  scenario "downloading a CSV template with activities for the current report" do
    click_link t("action.transaction.download.button")

    rows = CSV.parse(page.body, headers: true).map(&:to_h)

    expect(rows).to eq([
      {
        "Activity Name" => project.description,
        "Activity Delivery Partner Identifier" => project.delivery_partner_identifier,
        "Activity RODA Identifier" => project.roda_identifier_compound,
        "Date" => nil,
        "Value" => nil,
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
        "Disbursement Channel" => nil,
        "Description" => nil,
      },
      {
        "Activity Name" => sibling_project.description,
        "Activity Delivery Partner Identifier" => sibling_project.delivery_partner_identifier,
        "Activity RODA Identifier" => sibling_project.roda_identifier_compound,
        "Date" => nil,
        "Value" => nil,
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
        "Disbursement Channel" => nil,
        "Description" => nil,
      },
    ])
  end
end
