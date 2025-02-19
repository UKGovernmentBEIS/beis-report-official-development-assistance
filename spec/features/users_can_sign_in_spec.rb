require "rails_helper"
require "notify/otp_message"

def log_in_via_form(user, remember_me: false)
  click_on t("header.link.sign_in")
  # type in username and password
  fill_in "Email", with: user.email
  fill_in "Password", with: user.password

  check "Remember me" if remember_me

  click_on "Log in"
end

RSpec.feature "Users can sign in" do
  after { logout }

  context "user does not have 2FA enabled" do
    scenario "successful sign in via header link" do
      # Given a user exists
      user = create(:administrator)

      # When I log in with that user's credentials
      visit root_path
      expect(page).to have_content(t("start_page.title"))

      expect(page).to have_content(t("header.link.sign_in"))

      log_in_via_form(user)

      # Then I should be logged in.
      expect(page).to have_link(t("header.link.sign_out"))
      expect(page).to have_content("Signed in successfully.")

      # And at the home page
      expect(page).to have_content("You can search by RODA, Partner Organisation, BEIS, or IATI identifier, or by the activity's title")
    end
  end

  context "user has MFA enabled" do
    let(:notify_client) { spy("Notifications::Client") }

    before do
      allow_any_instance_of(Notify::OTPMessage).to receive(:client).and_return(notify_client)
    end

    context "user has a confirmed mobile number" do
      context "and the OTP is correct" do
        scenario "successful sign in via header link" do
          # Given a user with 2FA enabled and a confirmed mobile number exists
          user = create(:administrator, :mfa_enabled, mobile_number_confirmed_at: DateTime.current)
          allow_any_instance_of(User).to receive(:current_otp).and_return("123456")
          allow_any_instance_of(User).to receive(:validate_and_consume_otp!).and_return(true)
          allow(Notify::OTPMessage).to receive(:new).and_call_original

          # When I log in with that user's email and password
          travel_to Time.new(2023, 11, 29, 10, 0o0, 0o0) do
            visit root_path
            log_in_via_form(user)

            # Then there should be no link to check my mobile number
            expect(page).not_to have_link "Check your mobile number is correct"

            # And I should receive an OTP to my mobile number
            expect(Notify::OTPMessage).to have_received(:new).with(user.mobile_number, "123456")
          end

          # When I enter the one-time password before it expires
          travel_to Time.new(2023, 11, 29, 10, 0o5, 29) do
            fill_in "Please enter your six-digit verification code", with: "123456"
            click_on "Continue"
          end

          # Then I should be logged in
          expect(page).to have_content("Signed in successfully.")
          expect(page).to have_link(t("header.link.sign_out"))

          # And I should be at the home page
          expect(page).to have_content("You can search by RODA, Partner Organisation, BEIS, or IATI identifier, or by the activity's title")
        end
      end

      context "and the OTP has expired (Configured as 5 minutes, but appears to be 5 minutes 30 seconds)" do
        scenario "the see an error" do
          user = create(:administrator, :mfa_enabled, mobile_number_confirmed_at: DateTime.current)
          otp_at_time_of_login = nil

          travel_to Time.new(2023, 11, 29, 10, 0o0) do
            visit root_path
            log_in_via_form(user)
            otp_at_time_of_login = user.current_otp
          end

          travel_to Time.new(2023, 11, 29, 10, 0o5, 30) do
            fill_in "Please enter your six-digit verification code", with: otp_at_time_of_login
            click_on "Continue"
          end

          expect(page).to have_content("Invalid two-factor verification code.")
        end
      end

      scenario "unsuccessful OTP attempt" do
        # Given a user with 2FA enabled and a confirmed mobile number exists
        user = create(:administrator, :mfa_enabled, mobile_number_confirmed_at: DateTime.current)

        # When I log in with that user's email and password
        visit root_path
        log_in_via_form(user)

        # And I enter an incorrect OTP
        fill_in "Please enter your six-digit verification code", with: "000000"
        click_on "Continue"

        # Then I should not be logged in
        expect(page).to have_content("Invalid two-factor verification code")
        expect(page).not_to have_link(t("header.link.sign_out"))
        visit root_path
        expect(page).to have_content("Sign in")
      end

      scenario "logins can be remembered for 30 days" do
        # Given a user with 2FA enabled and a confirmed mobile number exists
        user = create(:administrator, :mfa_enabled, mobile_number_confirmed_at: DateTime.current)

        # When I log in with MFA and choose Remember me
        visit root_path
        log_in_via_form(user, remember_me: true)
        fill_in "Please enter your six-digit verification code", with: user.current_otp
        click_on "Continue"

        # Then I should be logged in
        expect(page).to have_link(t("header.link.sign_out"))
        expect(page).to have_content("Signed in successfully.")

        # And I should be at the home page
        expect(page).to have_content("You can search by RODA, Partner Organisation, BEIS, or IATI identifier, or by the activity's title")

        # When I visit the site 29 days later
        travel 29.days do
          visit reports_path

          # Then I should still be logged in
          expect(page).to have_content("Create a new report")
        end

        # When I visit the site 31 days later
        travel 31.days do
          visit reports_path

          # Then I should be logged out
          expect(page).to have_content("Sign in")
        end
      end
    end

    context "user initially entered an incorrect mobile number" do
      scenario "the email/password are correct but the user still needs confirm their mobile number" do
        incorrect_number = "123456wrong"
        # Given a user with 2FA enabled exists
        user = create(:administrator, :mfa_enabled, mobile_number_confirmed_at: nil, mobile_number: incorrect_number)

        # When I log in with that user's email and password
        visit root_path
        log_in_via_form(user)

        # But I do not receive a message despite it having been sent
        expect(notify_client).to have_received(:send_sms).once.with({
          phone_number: incorrect_number,
          template_id: ENV["NOTIFY_OTP_VERIFICATION_TEMPLATE"],
          personalisation: {otp: user.current_otp}
        })

        # When I follow the link to check my mobile number
        click_link "Check your mobile number is correct"

        # Then I should see the incorrect number
        expect(page).to have_field("Enter your mobile number", with: incorrect_number)

        # When I update my number
        correct_number = "07799000000"
        fill_in "Enter your mobile number", with: correct_number
        click_on "Continue"

        # Then I should receive an OTP to my mobile number
        expect(notify_client).to have_received(:send_sms).once.with({
          phone_number: correct_number,
          template_id: ENV["NOTIFY_OTP_VERIFICATION_TEMPLATE"],
          personalisation: {otp: user.current_otp}
        })

        # When I enter the one-time password before it expires
        fill_in "Please enter your six-digit verification code", with: user.current_otp
        expect(user.mobile_number_confirmed_at).to be_nil
        click_on "Continue"

        # Then my mobile number should be confirmed
        expect(user.reload.mobile_number_confirmed_at).to be_a(ActiveSupport::TimeWithZone)

        # And I should be logged in at the home page
        expect(page).to have_link(t("header.link.sign_out"))
        expect(page).to have_content("Signed in successfully.")
        expect(page).to have_content("You can search by RODA, Partner Organisation, BEIS, or IATI identifier, or by the activity's title")
      end
    end

    context "User has no mobile number provisioned" do
      scenario "successful mobile confirmation" do
        # Given that I am a RODA user
        user = create(:partner_organisation_user, :mfa_enabled, :no_mobile_number)

        # When I log in for the first time,
        visit root_path
        log_in_via_form(user, remember_me: true)

        # Then I am prompted for my mobile number
        expect(page).to have_content("Enter your mobile number")

        # And I enter my mobile number
        fill_in "Enter your mobile number", with: "07700900000"
        click_on "Continue"

        user = user.reload # Mobile number has changed

        # Then I should receive an automated text message,
        expect(notify_client).to have_received(:send_sms).with({
          phone_number: user.mobile_number,
          template_id: ENV["NOTIFY_OTP_VERIFICATION_TEMPLATE"],
          personalisation: {otp: user.current_otp}
        })

        # When I enter the code
        fill_in "Please enter your six-digit verification code", with: user.current_otp
        click_on "Continue"

        # Then I am successfully logged in.
        expect(page).to have_link(t("header.link.sign_out"))
        expect(page).to have_content("Signed in successfully.")

        # When I visit the site 29 days later
        travel 29.days do
          visit reports_path

          # Then I should still be logged in
          expect(page).to have_link(t("header.link.sign_out"))
        end
      end

      context "user enters an invalid mobile number" do
        let(:govuk_response) { double("Response", code: 400, body: "ValidationError: phone_number Not enough digits") }

        scenario "the email/password are correct but the mobile number is invalid" do
          # Given a user with 2FA enabled exists
          user = create(:administrator, :mfa_enabled, :no_mobile_number)

          # When I log in for the first time
          visit root_path
          log_in_via_form(user)

          # Then I am prompted for my mobile number
          expect(page).to have_content("Enter your mobile number")

          # And I enter an invalid mobile number
          invalid_number = "123456"
          fill_in "Enter your mobile number", with: invalid_number

          # And the notify service raises an error
          allow(notify_client).to receive(:send_sms).once.with({
            phone_number: invalid_number,
            template_id: ENV["NOTIFY_OTP_VERIFICATION_TEMPLATE"],
            personalisation: {otp: user.current_otp}
          }).and_raise(Notifications::Client::BadRequestError.new(govuk_response))

          click_on "Continue"

          # Then I should see an informative message
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("Not enough digits")

          # And I should be able to edit my mobile number
          expect(page).to have_field("Enter your mobile number")
        end
      end
    end

    scenario "they can sign in using a different capitalisation of their email address" do
      # Given a user exists
      user = create(:administrator, :mfa_enabled, email: "forename.lastname@somesite.org")

      # When I go to log in
      visit root_path
      click_on t("header.link.sign_in")

      # And I use a different capitalisation of the email than that in the database
      fill_in "Email", with: "Forename.Lastname@SOMEsite.org"
      fill_in "Password", with: user.password
      click_on "Log in"

      # Then I should be prompted for the OTP
      expect(page).to have_field("Please enter your six-digit verification code")
    end
  end

  scenario "a user is redirected to a link they originally requested" do
    user = create(:administrator)

    visit reports_path

    log_in_via_form(user)

    expect(current_path).to eq(reports_path)
  end

  scenario "a BEIS user lands on their home page" do
    user = create(:beis_user)

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    log_in_via_form(user)

    expect(page.current_path).to eql home_path
  end

  scenario "a partner organisation user lands on their home page" do
    user = create(:partner_organisation_user)

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    log_in_via_form(user)
    expect(page.current_path).to eql home_path
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit root_path

    expect(page).to have_content(t("start_page.title"))
  end

  context "incorrect credentials are supplied" do
    it "displays the error message so they can try to correct the problem themselves" do
      user = double("User", email: "dont@exist.com", password: "anything")

      visit root_path

      log_in_via_form(user)

      expect(page).to have_content("Invalid Email or password")
    end
  end

  context "when the user has been deactivated" do
    scenario "the user cannot log in and sees an informative message" do
      user = create(:partner_organisation_user, deactivated_at: DateTime.yesterday)

      visit root_path
      log_in_via_form(user)

      expect(page).to have_content("Your account is not active. If you believe this to be in error, please contact the person who invited you to the service.")
    end

    scenario "a user who is logged in and then deactivated sees an error message" do
      user = create(:partner_organisation_user)

      visit root_path
      log_in_via_form(user)

      expect(page.current_path).to eql home_path

      user.deactivated_at = DateTime.now
      user.save

      visit home_path

      expect(page).to have_content("Your account is not active. If you believe this to be in error, please contact the person who invited you to the service.")
    end
  end
end
