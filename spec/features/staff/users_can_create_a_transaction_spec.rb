RSpec.feature "Users can create a transaction" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      activity = create(:programme_activity)
      visit organisation_activity_path(activity.organisation, activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }
    let(:user) { create(:beis_user) }

    scenario "the form only shows relevant fields" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      visit activities_path

      click_on(activity.title)

      click_on(t("page_content.transactions.button.create"))

      expect(page).to have_content t("page_title.transaction.new")
      expect(page).to have_content t("form.label.transaction.value")
      expect(page).to have_content t("form.legend.transaction.receiving_organisation")
    end

    scenario "successfully creates a transaction on an activity" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      visit activities_path

      click_on(activity.title)

      click_on(t("page_content.transactions.button.create"))

      fill_in_transaction_form

      expect(page).to have_content(t("action.transaction.create.success"))
    end

    scenario "transaction creation is tracked with public_activity" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      PublicActivity.with_tracking do
        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in_transaction_form

        transaction = Transaction.last
        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "transaction.create"
        expect(auditable_event.owner_id).to eq user.id
        expect(auditable_event.trackable_id).to eq transaction.id
      end
    end

    context "when all values are missing" do
      scenario "validations" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))
        click_on(t("default.button.submit"))

        expect(page).to_not have_content(t("action.transaction.create.success"))
        expect(page).to have_content t("activerecord.errors.models.transaction.attributes.value.blank")
        expect(page).to have_content(t("activerecord.errors.models.transaction.attributes.receiving_organisation_name.blank"))
        expect(page).to have_content(t("activerecord.errors.models.transaction.attributes.receiving_organisation_type.blank"))
      end
    end

    context "when the value is not a number" do
      scenario "validations" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))
        fill_in "transaction[value]", with: "234r.67"
        click_on(t("default.button.submit"))

        expect(page).to_not have_content(t("action.transaction.create.success"))
        expect(page).to have_content t("activerecord.errors.models.transaction.attributes.value.not_a_number")
        expect(page).to have_content(t("activerecord.errors.models.transaction.attributes.receiving_organisation_name.blank"))
        expect(page).to have_content(t("activerecord.errors.models.transaction.attributes.receiving_organisation_type.blank"))
      end
    end

    context "Value number validation" do
      scenario "Value must be maximum 99,999,999,999" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in "transaction[value]", with: "100000000000"
        choose "4", name: "transaction[financial_quarter]"
        select "2019-2020", from: "transaction[financial_year]"
        click_on(t("default.button.submit"))

        expect(page).to have_content t("activerecord.errors.models.transaction.attributes.value.less_than_or_equal_to")
      end

      scenario "Value cannot be 0" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in "transaction[value]", with: "0"
        choose "4", name: "transaction[financial_quarter]"
        select "2019-2020", from: "transaction[financial_year]"
        click_on(t("default.button.submit"))

        expect(page).to have_content t("activerecord.errors.models.transaction.attributes.value.other_than")
      end

      scenario "Value can be negative" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in "transaction[value]", with: "-500000"
        choose "4", name: "transaction[financial_quarter]"
        select "2019-2020", from: "transaction[financial_year]"
        fill_in "transaction[receiving_organisation_name]", with: "Company"
        select "Government", from: "transaction[receiving_organisation_type]"
        click_on(t("default.button.submit"))

        expect(page).to have_content t("action.transaction.create.success")
      end

      scenario "When the value includes a pound sign" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "£123", expectations: false)

        expect(page).to have_content "123"
      end

      scenario "When the value includes alphabetical characters" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "abc123def", expectations: false)

        expect(page).to have_content "123"
      end

      scenario "When the value includes decimal places" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "100.12", expectations: false)

        expect(page).to have_content "100.12"
      end

      scenario "When the value includes commas" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "123,000,000", expectations: false)

        expect(page).to have_content "£123,000,000"
      end
    end

    scenario "they can cancel their transaction" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      visit activities_path

      click_on(activity.title)

      click_on(t("page_content.transactions.button.create"))

      click_on(t("form.link.activity.back"))

      expect(page).to have_content(activity.title)
    end
  end

  context "when they are a government delivery partner organisation user" do
    before { authenticate!(user: user) }
    let(:user) { create(:delivery_partner_user) }

    scenario "they cannot create transactions on a programme" do
      fund_activity = create(:fund_activity, :with_report, organisation: user.organisation)
      programme_activity = create(:programme_activity,
        parent: fund_activity,
        organisation: user.organisation,
        extending_organisation: user.organisation)

      visit organisation_activity_path(programme_activity.organisation, programme_activity)

      expect(page).not_to have_content(t("page_content.transactions.button.create"))
    end

    context "and the activity is a third-party project" do
      scenario "the transaction is associated with the currently active report" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)
        project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)

        visit organisation_activity_path(user.organisation, project)
        click_on "Add a transaction"

        fill_in_transaction_form

        transaction = Transaction.last
        report = Report.find_by(fund: fund, organisation: project.organisation)
        expect(transaction.report).to eq(report)
      end
    end

    scenario "when the activity cannot be edited they cannot see the add transaction button" do
      activity = create(:project_activity, organisation: user.organisation)
      _report = create(:report, state: :inactive, organisation: activity.organisation, fund: activity.associated_fund)

      visit organisation_activity_path(activity.organisation, activity)

      expect(page).not_to have_link t("page_content.transactions.button.create"), href: new_activity_transaction_path(activity)
    end
  end
end
