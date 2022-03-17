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

  before { allow(user).to receive(:send).with(:set_reset_password_token).and_return("123abc") }

  describe("#welcome") do
    it "sends a welcome email to the user with a set password link" do
      mail = described_class.welcome(user)

      expect(mail.to).to eq([user.email])

      headers = JSON.parse(mail.to_json)["header"]
      personalisation_header = headers.find { |h| h["name"] == "personalisation" }
      name = personalisation_header["unparsed_value"]["name"]
      link = personalisation_header["unparsed_value"]["link"]
      service_url = personalisation_header["unparsed_value"]["service_url"]

      expect(name).to eq(user.name)
      expect(link).to eq("http://test.local/users/password/edit?reset_password_token=123abc")
      expect(service_url).to eq("test.local")
    end
  end
end
