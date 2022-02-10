require "rails_helper"

RSpec.feature "Users can reset their password" do
  scenario "successful password reset" do
    # Given a user exists
    user = create(:administrator)

    # When I follow the reset password link
    visit root_path
    click_link "Sign in"
    click_link "Forgot password?"
    fill_in "Email address", with: user.email
    click_on "Submit"

    # Then I receive an email with the reset link
    expect(user).to have_received_email.with_subject("Reset password instructions")

    # When I follow the link in the email
    email = ActionMailer::Base.deliveries.last
    reset_password_link = email.body.raw_source.match(/(https?:\/\/\S+)/)
    visit reset_password_link

    # And I set a new password
    fill_in "New password", with: "letmein!"
    fill_in "Confirm new password", with: "letmein!"
    click_on "Change my password"

    # Then my password should be changed and I should be logged in
    expect(page).to have_content("Your password has been changed successfully. You are now signed in.")
  end
end
