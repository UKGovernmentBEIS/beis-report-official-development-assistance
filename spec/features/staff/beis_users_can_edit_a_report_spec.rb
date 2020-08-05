require "rails_helper"

RSpec.feature "BEIS users can edit a report" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let!(:report) { create(:report, organisation: delivery_partner_user.organisation, deadline: nil, description: "Legacy Report") }

  context "Logged in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    scenario "they can edit a Report to set the deadline" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit organisation_path(user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "2021"

      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.report.update.success")
      within "##{report.id}" do
        expect(page).to have_content("31 Jan 2021")
      end
    end

    scenario "editing a Report creates a log in PublicActivity" do
      PublicActivity.with_tracking do
        authenticate!(user: beis_user)
        report = create(:report)

        visit organisation_path(user.organisation)

        within "##{report.id}" do
          click_on I18n.t("default.link.edit")
        end

        fill_in "report[deadline(3i)]", with: "31"
        fill_in "report[deadline(2i)]", with: "1"
        fill_in "report[deadline(1i)]", with: "2021"

        click_on I18n.t("default.button.submit")

        auditable_events = PublicActivity::Activity.where(trackable_id: report.id)
        expect(auditable_events.map(&:key)).to include "report.update"
        expect(auditable_events.first.owner_id).to eq beis_user.id
      end
    end

    scenario "the deadline cannot be in the past" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit organisation_path(user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "2001"

      click_on I18n.t("default.button.submit")

      expect(page).to_not have_content I18n.t("action.report.update.success")
      expect(page).to have_content I18n.t("activerecord.errors.models.report.attributes.deadline.not_in_past")
    end

    scenario "the deadline cannot be very far in the future" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit organisation_path(user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "200020"

      click_on I18n.t("default.button.submit")

      expect(page).to_not have_content I18n.t("action.report.update.success")
      expect(page).to have_content I18n.t("activerecord.errors.models.report.attributes.deadline.between", min: 10, max: 25)
    end

    scenario "setting a Report's deadline changes its state to 'active'" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit organisation_path(user.organisation)

      within "##{report.id}" do
        expect(page).to have_content I18n.t("label.report.state.inactive")
        click_on I18n.t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "2021"

      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.report.update.success")
      within "##{report.id}" do
        expect(page).to have_content I18n.t("label.report.state.active")
      end
    end

    scenario "setting a Report's deadline logs an activity in PublicActivity" do
      PublicActivity.with_tracking do
        authenticate!(user: beis_user)
        report = create(:report)

        visit organisation_path(user.organisation)

        within "##{report.id}" do
          expect(page).to have_content I18n.t("label.report.state.inactive")
          click_on I18n.t("default.link.edit")
        end

        fill_in "report[deadline(3i)]", with: "31"
        fill_in "report[deadline(2i)]", with: "1"
        fill_in "report[deadline(1i)]", with: "2021"

        click_on I18n.t("default.button.submit")

        auditable_events = PublicActivity::Activity.where(trackable_id: report.id)
        expect(auditable_events.map(&:key)).to eq ["report.update", "report.activate"]
        expect(auditable_events.map(&:owner_id).uniq).to eq [beis_user.id]
      end
    end

    scenario "they can edit a Report to change the description (Reporting Period)" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit organisation_path(user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "report[description]", with: "Quarter 4 2020"

      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.report.update.success")

      within "##{report.id}" do
        expect(page).to have_content("Quarter 4 2020")
      end
    end

    scenario "the description (Reporting Period) cannot be blank" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit organisation_path(user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "report[description]", with: ""

      click_on I18n.t("default.button.submit")

      expect(page).to_not have_content I18n.t("action.report.update.success")
      expect(page).to have_content I18n.t("activerecord.errors.models.report.attributes.description.blank")
    end
  end

  context "Logged in as a Delivery Partner user" do
    scenario "they cannot edit a Report" do
      authenticate!(user: delivery_partner_user)

      visit organisation_path(delivery_partner_user.organisation)

      within "##{report.id}" do
        expect(page).to_not have_content(I18n.t("default.link.edit"))
      end
    end
  end
end
