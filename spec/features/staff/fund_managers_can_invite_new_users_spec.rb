require "rails_helper"

RSpec.feature "Fund managers can invite new users to the service" do
  before do
    stub_auth0_token_request
    stub_welcome_email_delivery
  end

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit new_user_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund manager" do
    before { authenticate!(user: build_stubbed(:fund_manager)) }

    scenario "a new user can be created" do
      first_organisation = create(:organisation)
      second_organisation = create(:organisation)

      new_user_name = "Foo Bar"
      new_user_email = "email@example.com"
      auth0_identifier = "auth0|00991122"

      stub_auth0_create_user_request(
        email: new_user_email,
        auth0_identifier: auth0_identifier
      )

      # Navigate from the landing page
      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_users"))

      # Navigate to the users page
      expect(page).to have_content(I18n.t("page_title.users.index"))

      # Create a new user
      click_on(I18n.t("page_content.users.button.create"))

      # Fill out the form
      expect(page).to have_content(I18n.t("page_title.users.new"))
      fill_in "user[name]", with: new_user_name
      fill_in "user[email]", with: new_user_email
      check first_organisation.name
      check second_organisation.name

      # Submit the form
      click_button I18n.t("generic.button.submit")

      within(".organisations") do
        expect(page).to have_content(first_organisation.name)
        expect(page).to have_content(second_organisation.name)
      end
    end

    context "when the name and email are not provided" do
      it "shows the user validation errors instead" do
        visit new_user_path

        expect(page).to have_content(I18n.t("page_title.users.new"))
        fill_in "user[name]", with: "" # deliberately omit a value
        fill_in "user[email]", with: "" # deliberately omit a value

        click_button I18n.t("generic.button.submit")

        expect(page).to have_content("Name can't be blank")
        expect(page).to have_content("Email can't be blank")
      end
    end

    context "when there was an error creating the user in auth0" do
      context "when there was a generic error" do
        it "does not create the user and displays an error message" do
          stub_auth0_token_request
          new_email = "email@example.com"
          stub_auth0_create_user_request_failure(email: new_email)

          visit new_user_path

          expect(page).to have_content(I18n.t("page_title.users.new"))
          fill_in "user[name]", with: "foo"
          fill_in "user[email]", with: new_email

          click_button I18n.t("generic.button.submit")

          expect(page).to have_content(I18n.t("form.user.create.failed"))
          expect(User.count).to eq(0)
        end
      end

      context "when the email was invalid" do
        it "does not create the user and displays an invalid email message" do
          new_email = "tom"
          stub_auth0_create_user_request_failure(email: new_email)

          visit new_user_path
          fill_in "user[name]", with: "tom"
          fill_in "user[email]", with: "tom"
          click_button I18n.t("generic.button.submit")

          expect(page).to have_content("Email is invalid")
          expect(page).not_to have_content(I18n.t("form.user.create.failed"))
        end
      end
    end

    context "when there are no organisations" do
      scenario "call to action to create a new organisation" do
        visit new_user_path

        expect(page).to have_content(I18n.t("page_content.users.new.no_organisations.cta"))

        click_on(I18n.t("page_content.users.new.no_organisations.link"))

        expect(page).to have_current_path(new_organisation_path)
      end
    end

    scenario "can go back to the previous page" do
      visit new_user_path

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(users_path)
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner)) }

    scenario "hides the 'Create user' button" do
      visit users_path

      expect(page).to have_no_content(I18n.t("page_content.users.button.create"))
    end

    scenario "shows the 'unauthorised' error message to the user" do
      visit new_user_path

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end
end
