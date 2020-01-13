require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  around do |example|
    ClimateControl.modify(
      NOTIFY_WELCOME_EMAIL_TEMPLATE: "123",
      DOMAIN: "test.local"
    ) do
      example.run
    end
  end

  let(:user) { create(:administrator) }
  before(:each) do
    stub_auth0_token_request
  end

  describe("#welcome") do
    it "sends a welcome email to the user with a set password link" do
      stub_auth0_post_password_change(auth0_identifier: user.identifier)

      mail = described_class.welcome(user)

      expect(mail.to).to eq([user.email])

      headers = JSON.parse(mail.to_json)["header"]
      personalisation_header = headers[4]
      name = personalisation_header["unparsed_value"]["name"]
      link = personalisation_header["unparsed_value"]["link"]
      service_url = personalisation_header["unparsed_value"]["service_url"]
      expect(name).to eq(user.name)
      expect(link).to eq("https://testdomain/lo/reset?ticket=123#")
      expect(service_url).to eq("test.local")
    end

    it "asks Auth0 for a password change token" do
      stub_auth0_post_password_change(auth0_identifier: user.identifier)

      mail = described_class.welcome(user)
      expect(mail.to).to eq([user.email])

      expect(stub_auth0_post_password_change).to have_been_requested
    end
  end
end
