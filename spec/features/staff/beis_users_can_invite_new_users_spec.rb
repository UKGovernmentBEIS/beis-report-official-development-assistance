RSpec.feature "BEIS users can invite new users to the service" do
  # context "when the user is not logged in" do
  #   it "redirects the user to the root path" do
  #     # Because it fails intermittently we need to comment out the whole block instead of using `pending`;
  #     # it only flips the failure state!
  #     pending "fails intermittently; look at as part of the user invite card."
  #
  #     visit new_user_path
  #     expect(current_path).to eq(root_path)
  #   end
  # end

  context "when the user is authenticated" do
    let(:user) { create(:administrator) }

    before do
      authenticate!(user: user)
    end

    context "when the user belongs to BEIS" do
      let(:user) { create(:beis_user) }

      scenario "a new user can be created" do
        organisation = create(:delivery_partner_organisation)
        second_organisation = create(:delivery_partner_organisation)
        new_user_name = "Foo Bar"
        new_user_email = "email@example.com"

        perform_enqueued_jobs do
          create_user(organisation, new_user_name, new_user_email)
        end

        expect(page).to have_content(organisation.name)
        expect(page).not_to have_content(second_organisation.name)

        new_user = User.where(email: new_user_email).first
        reset_password_link_regex = %r{http://test.local/users/password/edit\?reset_password_token=.*}
        expect(new_user).to have_received_email.with_personalisations(
          link: match(reset_password_link_regex),
          name: new_user_name,
          service_url: "test.local"
        )
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
    end

    context "when the user does not belong to BEIS" do
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
      beis_identifier = Organisation.service_owner.id
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
