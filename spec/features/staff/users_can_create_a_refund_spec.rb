RSpec.feature "Users can create a refund" do
  let(:organisation) { create(:delivery_partner_organisation) }

  RSpec.shared_examples "refunds" do
    before { authenticate!(user: user) }

    scenario "they can create a refund for an activity" do
      visit new_activity_refund_path(activity_id: activity.id)

      fill_in "refund[value]", with: "100"

      choose "4", name: "refund[financial_quarter]"
      select "2019-2020", from: "refund[financial_year]"
      fill_in "refund[comment]", with: "Comment goes here"

      expect { click_on(t("default.button.submit")) }.to change(Refund, :count).by(1)

      expect(page).to have_content(t("action.refund.create.success"))
    end
  end

  context "when logged in as a BEIS user" do
    include_examples "refunds" do
      let(:user) { create(:beis_user) }
      let(:activity) { create(:programme_activity, :with_report) }
    end
  end

  context "when logged in as a delivery partner" do
    include_examples "refunds" do
      let(:user) { create(:delivery_partner_user, organisation: organisation) }
      let(:activity) { create(:project_activity, :with_report, organisation: organisation) }
    end
  end
end
