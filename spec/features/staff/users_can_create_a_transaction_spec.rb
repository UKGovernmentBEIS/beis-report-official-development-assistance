RSpec.feature "Users can create an actual" do
  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }
    let(:user) { create(:beis_user) }

    scenario "the form only shows relevant fields" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)

      click_on(t("page_content.actuals.button.create"))

      expect(page).to have_content t("page_title.actual.new")
      expect(page).to have_content t("form.label.actual.value")
      expect(page).to have_content t("form.legend.actual.receiving_organisation")
    end

    scenario "successfully creates a actual on an activity" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)

      click_on(t("page_content.actuals.button.create"))

      fill_in_actual_form

      expect(page).to have_content(t("action.actual.create.success"))
    end

    context "when all values are missing" do
      scenario "validations" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))
        click_on(t("default.button.submit"))

        expect(page).to_not have_content(t("action.actual.create.success"))
        expect(page).to have_content t("activerecord.errors.models.actual.attributes.value.blank")
      end
    end

    context "when the value is not a number" do
      scenario "validations" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))
        fill_in "actual[value]", with: "234r.67"
        click_on(t("default.button.submit"))

        expect(page).to_not have_content(t("action.actual.create.success"))
        expect(page).to have_content t("activerecord.errors.models.actual.attributes.value.not_a_number")
      end
    end

    context "Value number validation" do
      scenario "Value must be maximum 99,999,999,999" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in "actual[value]", with: "100000000000"
        choose "4", name: "actual[financial_quarter]"
        select "2019-2020", from: "actual[financial_year]"
        click_on(t("default.button.submit"))

        expect(page).to have_content t("activerecord.errors.models.actual.attributes.value.less_than_or_equal_to")
      end

      scenario "Value cannot be 0" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in "actual[value]", with: "0"
        choose "4", name: "actual[financial_quarter]"
        select "2019-2020", from: "actual[financial_year]"
        click_on(t("default.button.submit"))

        expect(page).to have_content t("activerecord.errors.models.actual.attributes.value.other_than")
      end

      scenario "Value can be negative" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in "actual[value]", with: "-500000"
        choose "4", name: "actual[financial_quarter]"
        select "2019-2020", from: "actual[financial_year]"
        fill_in "actual[receiving_organisation_name]", with: "Company"
        select "Government", from: "actual[receiving_organisation_type]"
        click_on(t("default.button.submit"))

        expect(page).to have_content t("action.actual.create.success")
      end

      scenario "When the value includes a pound sign" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(value: "£123", expectations: false)

        expect(page).to have_content "123"
      end

      scenario "When the value includes alphabetical characters" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(value: "abc123def", expectations: false)

        expect(page).to have_content "123"
      end

      scenario "When the value includes decimal places" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(value: "100.12", expectations: false)

        expect(page).to have_content "100.12"
      end

      scenario "When the value includes commas" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(value: "123,000,000", expectations: false)

        expect(page).to have_content "£123,000,000"
      end
    end

    context "organisation validation" do
      it "shows an error when the organisation type is blank, but not the name" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(
          receiving_organisation: OpenStruct.new(name: "Example receiver", reference: "GB-COH-123", type: nil),
          expectations: false
        )

        expect(page).to have_content(t("activerecord.errors.models.actual.attributes.receiving_organisation_type.blank"))
      end

      it "shows an error when the organisation name is blank, but not the type" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(
          receiving_organisation: OpenStruct.new(name: nil, reference: "GB-COH-123", type: "Private Sector"),
          expectations: false
        )

        expect(page).to have_content(t("activerecord.errors.models.actual.attributes.receiving_organisation_name.blank"))
      end

      it "shows errors if the organisation reference is present, but not the name or reference" do
        activity = create(:programme_activity, :with_report, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form(
          receiving_organisation: OpenStruct.new(name: nil, reference: "GB-COH-123", type: nil),
          expectations: false
        )

        expect(page).to have_content(t("activerecord.errors.models.actual.attributes.receiving_organisation_name.blank"))
        expect(page).to have_content(t("activerecord.errors.models.actual.attributes.receiving_organisation_type.blank"))
      end
    end

    scenario "they can cancel their actual" do
      activity = create(:programme_activity, :with_report, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)

      click_on(t("page_content.actuals.button.create"))

      click_on(t("form.link.activity.back"))

      expect(page).to have_content(activity.title)
    end
  end

  context "when they are a government delivery partner organisation user" do
    before { authenticate!(user: user) }
    let(:user) { create(:delivery_partner_user) }
    let(:beis_user) { create(:beis_user) }

    scenario "they cannot create actuals on a programme" do
      fund_activity = create(:fund_activity, :with_report)
      programme_activity = create(:programme_activity,
        parent: fund_activity,
        extending_organisation: user.organisation)

      visit organisation_activity_path(programme_activity.organisation, programme_activity)

      expect(page).not_to have_content(t("page_content.actuals.button.create"))
    end

    context "and the activity is a third-party project" do
      scenario "the actual is associated with the currently active report" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)
        project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)

        visit organisation_activity_path(user.organisation, project)
        click_on(t("page_content.actuals.button.create"))

        fill_in_actual_form

        actual = Actual.last
        report = Report.find_by(fund: fund, organisation: project.organisation)
        expect(actual.report).to eq(report)
      end
    end

    scenario "when the activity cannot be edited they cannot see the add actual button" do
      activity = create(:project_activity, organisation: user.organisation)
      _report = create(:report, state: :inactive, organisation: activity.organisation, fund: activity.associated_fund)

      visit organisation_activity_path(activity.organisation, activity)

      expect(page).not_to have_link t("page_content.actuals.button.create"), href: new_activity_transaction_path(activity)
    end
  end
end
