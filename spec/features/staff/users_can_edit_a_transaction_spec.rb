RSpec.feature "Users can edit a transaction" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let!(:activity) { create(:activity, organisation: organisation) }
  let!(:transaction) { create(:transaction, activity: activity) }
  let(:user) { create(:administrator, organisation: organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit activity_step_path(double(Activity, id: "123"), :identifier)
      expect(current_path).to eq(root_path)
    end
  end

  scenario "going back to the previous page" do
    visit organisation_path(organisation)
    click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
    click_on(organisation.name)
    click_on(activity.title)

    expect(page).to have_content(transaction.reference)

    within("##{transaction.id}") do
      click_on(I18n.t("generic.link.edit"))
    end
    click_on(I18n.t("generic.link.back"))

    expect(page).to have_content(activity.title)
  end

  scenario "editing a transaction" do
    visit organisation_path(organisation)
    click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
    click_on(organisation.name)
    click_on(activity.title)

    expect(page).to have_content(transaction.reference)

    within("##{transaction.id}") do
      click_on(I18n.t("generic.link.edit"))
    end

    fill_in_transaction_form(
      reference: "new-transaction-reference",
      description: "This money will be buying some books for students",
      transaction_type: "Expenditure",
      date_day: "1",
      date_month: "1",
      date_year: "2021",
      value: "2000.51",
      disbursement_channel: "Aid in kind: Donors manage funds themselves",
      currency: "US Dollar"
    )

    expect(page).to have_content(I18n.t("form.transaction.update.success"))
  end
end
