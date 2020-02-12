RSpec.feature "Users can view transactions on an activity page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }

  context "when the user is a fund manager" do
    let(:user) { create(:fund_manager, organisation: organisation) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: organisation) }
      let(:other_activity) { create(:fund_activity, organisation: organisation) }

      scenario "only transactions belonging to this activity are shown on the Activity#show page" do
        transaction = create(:transaction, activity: activity)
        other_transaction = create(:transaction, activity: other_activity)

        visit organisations_path
        click_link organisation.name
        click_link activity.title

        expect(page).to have_content(transaction.reference)
        expect(page).to_not have_content(other_transaction.reference)
      end

      scenario "transaction information is shown on the page" do
        transaction = create(:transaction, activity: activity)

        visit organisations_path
        click_link organisation.name
        click_link activity.title

        transaction_details_are_present(transaction)
      end
    end

    context "when the activity is a programme" do
      let(:fund_activity) { create(:fund_activity, organisation: organisation) }
      let(:activity) { create(:programme_activity, activity: fund_activity, organisation: organisation) }

      scenario "transaction information is shown on the page" do
        transaction = create(:transaction, activity: activity)

        visit organisations_path
        click_link organisation.name
        click_link fund_activity.title
        click_link activity.title

        transaction_details_are_present(transaction)
      end
    end

    context "when the activity is a project" do
      let(:fund_activity) { create(:fund_activity, organisation: organisation) }
      let(:programme_activity) { create(:programme_activity, activity: fund_activity) }
      let(:activity) { create(:project_activity, activity: programme_activity, organisation: organisation) }

      scenario "transaction information is shown on the page" do
        transaction = create(:transaction, activity: activity)

        visit organisations_path
        click_link organisation.name
        click_link fund_activity.title
        click_link programme_activity.title
        click_link activity.title

        transaction_details_are_present(transaction)
      end
    end
  end

  context "when the user is a delivery partner" do
    let(:user) { create(:delivery_partner, organisation: organisation) }

    context "when the activity is a programme" do
      let(:fund_activity) { create(:fund_activity, organisation: organisation) }
      let(:activity) { create(:programme_activity, activity: fund_activity, organisation: organisation) }

      scenario "transaction information is not shown on the page" do
        transaction = create(:transaction, activity: activity)

        visit organisation_path(organisation)
        click_link fund_activity.title
        click_link activity.title

        expect(page).to_not have_content(transaction.reference)
      end
    end

    context "when the activity is a project" do
      let(:fund_activity) { create(:fund_activity, organisation: organisation) }
      let(:programme_activity) { create(:programme_activity, activity: fund_activity, organisation: organisation) }
      let(:activity) { create(:project_activity, activity: programme_activity, organisation: organisation) }

      scenario "transaction information is shown on the page" do
        transaction = create(:transaction, activity: activity)

        visit organisation_path(organisation)
        click_link fund_activity.title
        click_link programme_activity.title
        click_link activity.title

        transaction_details_are_present(transaction)
      end
    end
  end

  def transaction_details_are_present(transaction)
    transaction_presenter = TransactionPresenter.new(transaction)

    expect(page).to have_content(transaction_presenter.reference)
    expect(page).to have_content(transaction_presenter.description)
    expect(page).to have_content(transaction_presenter.transaction_type)
    expect(page).to have_content(transaction_presenter.date)
    expect(page).to have_content(transaction_presenter.currency)
    expect(page).to have_content(transaction_presenter.value)
    expect(page).to have_content(transaction_presenter.disbursement_channel)
    expect(page).to have_content(transaction_presenter.providing_organisation_name)
    expect(page).to have_content(transaction_presenter.receiving_organisation_name)
  end
end
