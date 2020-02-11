require "rails_helper"

RSpec.describe "Users can create a project level activity" do
  let(:organisation) { create(:organisation, name: "UKSA") }
  let!(:fund) { create(:fund_activity, organisation: organisation) }
  let!(:programme) { create(:programme_activity, activity: fund, organisation: organisation) }

  before do
    authenticate!(user: user)
  end

  context "as a fund manager" do
    let(:user) { create(:fund_manager, organisation: organisation) }

    context "on a programme" do
      scenario "successfully create a project" do
        visit organisation_path(organisation)
        click_on fund.title
        click_on programme.title

        click_on(I18n.t("page_content.organisation.button.create_project"))

        fill_in_activity_form

        expect(page).to have_content I18n.t("form.project.create.success")
      end
    end

    context "on a fund" do
      scenario "a project cannot be created on a fund" do
        visit organisation_path(organisation)
        click_on fund.title

        expect(page).to_not have_content(I18n.t("page_content.organisation.button.create_project"))
      end
    end
  end

  context "as a delivery partner" do
    let(:user) { create(:delivery_partner, organisation: organisation) }

    context "on a programme" do
      scenario "successfully create a project" do
        visit organisation_path(organisation)
        click_on fund.title
        click_on programme.title

        click_on(I18n.t("page_content.organisation.button.create_project"))

        fill_in_activity_form

        expect(page).to have_content I18n.t("form.project.create.success")
      end
    end

    context "on a fund" do
      scenario "a project cannot be created on a fund" do
        visit organisation_path(organisation)
        click_on fund.title

        expect(page).to_not have_content I18n.t("page_content.organisation.button.create_project")
      end
    end
  end
end
