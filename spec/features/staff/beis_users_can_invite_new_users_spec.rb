RSpec.feature "BEIS users can invite new users to the service" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit new_user_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is authenticated" do
    let(:user) { create(:administrator) }

    before do
      authenticate!(user: user)
    end

    before do
      stub_auth0_token_request
    end

    context "when the user belongs to BEIS" do
      let(:user) { create(:beis_user) }

      scenario "a new user can be created" do
        organisation = create(:organisation)
        second_organisation = create(:organisation)
        new_user_name = "Foo Bar"
        new_user_email = "email@example.com"
        auth0_identifier = "auth0|00991122"

        stub_auth0_create_user_request(
          email: new_user_email,
          auth0_identifier: auth0_identifier
        )
        stub_auth0_post_password_change(
          auth0_identifier: auth0_identifier
        )

        perform_enqueued_jobs do
          create_user(organisation, new_user_name, new_user_email)
        end

        expect(page).to have_content(organisation.name)
        expect(page).not_to have_content(second_organisation.name)

        new_user = User.where(email: new_user_email).first

        expect(new_user).to have_received_email.with_personalisations(
          "name" => new_user_name,
          "link" => "https://testdomain/lo/reset?ticket=123#",
          "service_url" => "test.local"
        )
      end

      scenario "user creation is tracked with public_activity" do
        PublicActivity.with_tracking do
          organisation = create(:organisation)
          new_user_name = "Foo Bar"
          new_user_email = "email@example.com"
          auth0_identifier = "auth0|00991122"

          stub_auth0_create_user_request(
            email: new_user_email,
            auth0_identifier: auth0_identifier
          )

          create_user(organisation, new_user_name, new_user_email)
          auditable_events = PublicActivity::Activity.all
          expect(auditable_events.map { |event| event.key }).to include("user.create")
          expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
        end
      end

      context "when the name and email are not provided" do
        it "shows the user validation errors instead" do
          visit new_user_path

          expect(page).to have_content(t("page_title.users.new"))
          fill_in "user[name]", with: "" # deliberately omit a value
          fill_in "user[email]", with: "" # deliberately omit a value

          click_button t("default.button.submit")

          expect(page).to have_content(t("activerecord.errors.models.user.attributes.name.blank"))
          expect(page).to have_content(t("activerecord.errors.models.user.attributes.email.blank"))
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

            expect(page).to have_content(t("page_title.users.new"))
            fill_in "user[name]", with: "foo"
            fill_in "user[email]", with: new_email
            choose organisation.name

            expect {
              click_button t("default.button.submit")
            }.not_to change { User.count }

            expect(page).to have_content(t("action.user.create.failed", error: "The user already exists."))
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

            click_button t("default.button.submit")

            expect(page).to have_content("Email is invalid")
            expect(page).not_to have_content(t("action.user.create.failed"))
          end
        end
      end
    end

    context "when the user does not belongs to BEIS" do
      let(:user) { create(:delivery_partner_user) }

      it "does not show them the manage user button" do
        visit organisation_path(user.organisation)
        expect(page).not_to have_content(t("page_title.users.index"))
      end
    end
  end

  def create_user(organisation, new_user_name, new_user_email)
    # Navigate from the landing page
    visit organisation_path(organisation)
    click_on(t("page_title.users.index"))

    # Navigate to the users page
    expect(page).to have_content(t("page_title.users.index"))

    # Create a new user
    click_on(t("page_content.users.button.create"))

    # We expect to see BEIS separately on this page
    within(".user-organisations") do
      beis_identifier = Organisation.find_by(service_owner: true).id
      expect(page).to have_css("input[type='radio'][value='#{beis_identifier}']:first-child")
      expect(page).to have_css(".govuk-radios__divider:nth-child(2)")
    end

    # Fill out the form
    expect(page).to have_content(t("page_title.users.new"))
    fill_in "user[name]", with: new_user_name
    fill_in "user[email]", with: new_user_email
    choose organisation.name

    # Submit the form
    click_button t("default.button.submit")
  end
end
