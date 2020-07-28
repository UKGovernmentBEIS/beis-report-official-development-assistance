require "rails_helper"

RSpec.feature "BEIS users can edit a submission" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let!(:submission) { create(:submission, organisation: delivery_partner_user.organisation, deadline: nil, description: "Legacy Submission") }

  context "Logged in as a BEIS user" do
    scenario "they can edit a Submission to set the deadline" do
      user = create(:beis_user)
      authenticate!(user: user)

      visit organisation_path(user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "submission[deadline(3i)]", with: "31"
      fill_in "submission[deadline(2i)]", with: "1"
      fill_in "submission[deadline(1i)]", with: "2021"

      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.submission.update.success")
      within "##{submission.id}" do
        expect(page).to have_content("31 Jan 2021")
      end
    end

    scenario "editing a Submission creates a log in PublicActivity" do
      PublicActivity.with_tracking do
        user = create(:beis_user)
        authenticate!(user: user)

        visit organisation_path(user.organisation)

        within "##{submission.id}" do
          click_on I18n.t("default.link.edit")
        end

        fill_in "submission[deadline(3i)]", with: "31"
        fill_in "submission[deadline(2i)]", with: "1"
        fill_in "submission[deadline(1i)]", with: "2021"

        click_on I18n.t("default.button.submit")

        auditable_events = PublicActivity::Activity.where(trackable_id: submission.id)
        expect(auditable_events.map(&:key)).to include "submission.update"
        expect(auditable_events.first.owner_id).to eq user.id
      end
    end

    scenario "the deadline cannot be in the past" do
      user = create(:beis_user)
      authenticate!(user: user)

      visit organisation_path(user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "submission[deadline(3i)]", with: "31"
      fill_in "submission[deadline(2i)]", with: "1"
      fill_in "submission[deadline(1i)]", with: "2001"

      click_on I18n.t("default.button.submit")

      expect(page).to_not have_content I18n.t("action.submission.update.success")
      expect(page).to have_content I18n.t("activerecord.errors.models.submission.attributes.deadline.not_in_past")
    end

    scenario "the deadline cannot be very far in the future" do
      user = create(:beis_user)
      authenticate!(user: user)

      visit organisation_path(user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "submission[deadline(3i)]", with: "31"
      fill_in "submission[deadline(2i)]", with: "1"
      fill_in "submission[deadline(1i)]", with: "200020"

      click_on I18n.t("default.button.submit")

      expect(page).to_not have_content I18n.t("action.submission.update.success")
      expect(page).to have_content I18n.t("activerecord.errors.models.submission.attributes.deadline.between", min: 10, max: 25)
    end

    scenario "setting a Submission's deadline changes its state to 'active'" do
      user = create(:beis_user)
      authenticate!(user: user)

      visit organisation_path(user.organisation)

      within "##{submission.id}" do
        expect(page).to have_content I18n.t("label.submission.state.inactive")
        click_on I18n.t("default.link.edit")
      end

      fill_in "submission[deadline(3i)]", with: "31"
      fill_in "submission[deadline(2i)]", with: "1"
      fill_in "submission[deadline(1i)]", with: "2021"

      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.submission.update.success")
      within "##{submission.id}" do
        expect(page).to have_content I18n.t("label.submission.state.active")
      end
    end

    scenario "setting a Submission's deadline logs an activity in PublicActivity" do
      PublicActivity.with_tracking do
        user = create(:beis_user)
        authenticate!(user: user)

        visit organisation_path(user.organisation)

        within "##{submission.id}" do
          expect(page).to have_content I18n.t("label.submission.state.inactive")
          click_on I18n.t("default.link.edit")
        end

        fill_in "submission[deadline(3i)]", with: "31"
        fill_in "submission[deadline(2i)]", with: "1"
        fill_in "submission[deadline(1i)]", with: "2021"

        click_on I18n.t("default.button.submit")

        auditable_event = PublicActivity::Activity.find_by(trackable_id: submission.id)
        expect(auditable_event.key).to eq "submission.activate"
        expect(auditable_event.owner_id).to eq user.id
      end
    end

    scenario "they can edit a Submission to change the description (Reporting Period)" do
      user = create(:beis_user)
      authenticate!(user: user)

      visit organisation_path(user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "submission[description]", with: "Quarter 4 2020"

      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.submission.update.success")
      within "##{submission.id}" do
        expect(page).to have_content("Quarter 4 2020")
      end
    end

    scenario "the description (Reporting Period) cannot be blank" do
      user = create(:beis_user)
      authenticate!(user: user)

      visit organisation_path(user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.edit")
      end

      fill_in "submission[description]", with: ""

      click_on I18n.t("default.button.submit")

      expect(page).to_not have_content I18n.t("action.submission.update.success")
      expect(page).to have_content I18n.t("activerecord.errors.models.submission.attributes.description.blank")
    end
  end

  context "Logged in as a Delivery Partner user" do
    scenario "they cannot edit a Submission" do
      authenticate!(user: delivery_partner_user)

      visit organisation_path(delivery_partner_user.organisation)

      within "##{submission.id}" do
        expect(page).to_not have_content(I18n.t("default.link.edit"))
      end
    end
  end
end
