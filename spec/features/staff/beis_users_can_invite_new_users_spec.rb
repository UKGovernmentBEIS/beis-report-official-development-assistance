RSpec.feature "BEIS users can invite new users to the service" do
  let(:user) { create(:administrator) }

  before do
    authenticate!(user: user)
  end

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

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

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
      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.dashboard.button.manage_users"))

      # Navigate to the users page
      expect(page).to have_content(I18n.t("page_title.users.index"))

      # Create a new user
      click_on(I18n.t("page_content.users.button.create"))

      # Fill out the form
      expect(page).to have_content(I18n.t("page_title.users.new"))
      fill_in "user[name]", with: new_user_name
      fill_in "user[email]", with: new_user_email
      choose first_organisation.name

      # Submit the form
      click_button I18n.t("generic.button.submit")

      expect(page).to have_content(first_organisation.name)
      expect(page).not_to have_content(second_organisation.name)
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
          organisation = create(:organisation)
          stub_auth0_create_user_request_failure(email: new_email)

          visit new_user_path

          expect(page).to have_content(I18n.t("page_title.users.new"))
          fill_in "user[name]", with: "foo"
          fill_in "user[email]", with: new_email
          choose organisation.name

          expect {
            click_button I18n.t("generic.button.submit")
          }.not_to change { User.count }

          expect(page).to have_content(I18n.t("form.user.create.failed", error: "The user already exists."))
        end
      end

      context "when the email was invalid" do
        it "does not create the user and displays an invalid email message" do
          new_email = "tom"
          organisation = create(:organisation)
          stub_auth0_create_user_request_failure(email: new_email)

          visit new_user_path
          fill_in "user[name]", with: "tom"
          fill_in "user[email]", with: "tom"
          choose organisation.name

          click_button I18n.t("generic.button.submit")

          expect(page).to have_content("Email is invalid")
          expect(page).not_to have_content(I18n.t("form.user.create.failed"))
        end
      end
    end

    scenario "can go back to the previous page" do
      visit new_user_path

      click_on I18n.t("generic.link.back")
      expect(page).to have_current_path(users_path)
    end
  end

  context "when the user does not belongs to BEIS" do
    let(:user) { create(:delivery_partner_user) }

    it "does not show them the manage user button" do
      visit organisation_path(user.organisation)
      expect(page).not_to have_content(I18n.t("page_content.dashboard.button.manage_users"))
    end
  end
end
