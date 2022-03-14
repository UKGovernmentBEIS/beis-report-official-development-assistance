require "rails_helper"
require "notify/otp_message"

RSpec.feature "Users can reset their password" do
  let(:notify_client) { spy("Notifications::Client") }

  before do
    allow_any_instance_of(Notify::OTPMessage).to receive(:client).and_return(notify_client)
  end

  scenario "successful password reset" do
    # Given a user exists
    user = create(:administrator, :mfa_enabled)

    # When I follow the reset password link
    visit root_path
    click_link "Sign in"
    click_link "Forgot password?"

    # When I fill in a valid email address that is not registered
    fill_in "Email address", with: "notregistered@example.org"
    click_on "Submit"

    # Then I should see a generic message that doesn't disclose that the email is not registered
    expect(page).to have_content("If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.")

    # When I fill in my email address
    click_link "Forgot password?"
    fill_in "Email address", with: user.email
    click_on "Submit"

    # Then I receive an email with the reset link
    expect(user).to have_received_email.with_subject("Reset password instructions")

    # When I follow the link in the email
    email = ActionMailer::Base.deliveries.last
    reset_password_link = email.body.raw_source.match(/(https?:\/\/\S+)/)
    visit reset_password_link

    # Then I should see a password hint with the full requirements
    expect(page).to have_content("Minimum 15 characters; must contain at least one digit, one lowercase letter, one uppercase letter, and one punctuation mark or symbol")

    # When I try to set a password that doesn't fulfill the requirements
    fill_in "New password", with: "LlEeTtMmEeIinnn"
    fill_in "Confirm new password", with: "LlEeTtMmEeIinnn"
    click_on "Change my password"

    # Then I should see an error message complying with GOV.UK guidelines
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Password must contain at least one digit")

    # When I set a password that fulfills the requirements
    fill_in "New password", with: "LlEeTtMmEeIin1!"
    fill_in "Confirm new password", with: "LlEeTtMmEeIin1!"
    click_on "Change my password"

    # Then I should be asked to log in with my new password
    expect(page).to have_content("Your password has been changed successfully. Please log in with your new password")
  end
end
