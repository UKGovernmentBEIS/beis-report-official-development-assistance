RSpec.feature "BEIS users can invite new users to the service" do
  let(:user) { create(:administrator) }

  before do
    authenticate!(user: user)
  end
  after { logout }

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    scenario "a new user can be created", js: true do
      organisation = create(:partner_organisation)
      second_organisation = create(:partner_organisation)
      additional_organisation = create(:partner_organisation)
      new_user_name = "Foo Bar"
      new_user_email = "email@example.com"

      perform_enqueued_jobs do
        create_user(organisation, additional_organisation, new_user_name, new_user_email)
      end

      expect(page).to have_content(organisation.name)
      expect(page).not_to have_content(second_organisation.name)
      expect(page).to have_content(additional_organisation.name)

      new_user = User.where(email: new_user_email).first
      reset_password_link_regex = %r{http://test.local/users/password/edit\?reset_password_token=.*}
      expect(new_user).to have_received_email.with_personalisations(
        link: match(reset_password_link_regex),
        name: new_user_name,
        service_url: "test.local"
      )
    end

    scenario "when DSIT is the organisation and the email address is not whitelisted, it shows a confirm modal", js: true do
      organisation = create(:beis_organisation)
      create(:partner_organisation)
      additional_organisation = create(:partner_organisation)
      new_user_name = "Foo Bar"
      new_user_email = "email@example.com"

      perform_enqueued_jobs do
        create_user(organisation, additional_organisation, new_user_name, new_user_email) do
          warning = t("form.user.modal.warn_on_non_dsit")
          accept_confirm warning do
            click_button "Submit"
          end
        end
      end
    end

    scenario "when DSIT as the organisation and the email address is whitelisted, no confirm modal is shown", js: true do
      organisation = create(:beis_organisation)
      create(:partner_organisation)
      additional_organisation = create(:partner_organisation)
      new_user_name = "Foo Bar"
      new_user_email = "email@odamanagement.org"

      perform_enqueued_jobs do
        create_user(organisation, additional_organisation, new_user_name, new_user_email) do
          expect do
            accept_confirm do
              click_button "Submit"
            end
          end.to raise_error(Capybara::ModalNotFound)
        end
      end
    end

    context "when the name and email are not provided" do
      it "shows the user validation errors instead" do
        visit new_user_path

        expect(page).to have_content("Create user")
        fill_in "user[name]", with: "" # deliberately omit a value
        fill_in "user[email]", with: "" # deliberately omit a value

        click_button "Submit"

        expect(page).to have_content("Enter a full name")
        expect(page).to have_content("Enter an email address")
      end
    end
  end

  context "when the user does not belong to BEIS" do
    let(:user) { create(:partner_organisation_user) }

    it "does not show them the manage user button" do
      visit organisation_path(user.organisation)
      expect(page).not_to have_content("Users")
    end
  end

  def create_user(organisation, additional_organisation, new_user_name, new_user_email)
    # Navigate from the landing page
    visit organisation_path(organisation)
    click_on("Users")

    # Navigate to the users page
    expect(page).to have_content("Users")

    # Create a new user
    click_on("Add user")

    # We expect to see BEIS on this page in the dropdown
    within(".user-organisations") do
      beis_identifier = Organisation.service_owner.id
      expect(page).to have_css("select option[value='#{beis_identifier}']")
    end

    # We expect to see the additional organisation too
    within(".additional-organisations") do
      # Target the `label` here because with JS on, the inputs are hidden!
      expect(page).to have_css("label[for='user-additional-organisations-#{additional_organisation.id}-field']")
    end

    # Fill out the form
    expect(page).not_to have_content("Reset the user's mobile number?")
    expect(page).to have_content("Create user")
    fill_in "user[name]", with: new_user_name
    fill_in "user[email]", with: new_user_email
    select organisation.name
    check additional_organisation.name

    if block_given?
      yield
    else
      # Submit the form
      click_button "Submit"
    end
  end
end
