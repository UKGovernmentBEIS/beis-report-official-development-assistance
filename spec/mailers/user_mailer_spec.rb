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
    let(:mail) { described_class.welcome(user) }

    let(:personalisation_header) do
      headers = JSON.parse(mail.to_json)["header"]
      headers.find { |h| h["name"] == "personalisation" }["unparsed_value"]
    end

    it "sends a welcome email to the user with a set password link" do
      expect(mail.to).to eq([user.email])

      name = personalisation_header["name"]
      link = personalisation_header["link"]
      service_url = personalisation_header["service_url"]
      environment_mailer_prefix = personalisation_header["environment_mailer_prefix"]

      expect(name).to eq(user.name)
      expect(link).to eq("http://test.local/users/password/edit?reset_password_token=123abc")
      expect(service_url).to eq("test.local")
      expect(environment_mailer_prefix).to eql("")
    end

    context "when the email is from the training site" do
      it "includes the environment name in the email personalisations" do
        ClimateControl.modify CANONICAL_HOSTNAME: "training.report-official-development-assistance.service.gov.uk" do
          environment_mailer_prefix = personalisation_header["environment_mailer_prefix"]

          expect(environment_mailer_prefix).to eql("[Training] ")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the environment name in the email personalisations" do
        ClimateControl.modify CANONICAL_HOSTNAME: "www.report-official-development-assistance.service.gov.uk" do
          environment_mailer_prefix = personalisation_header["environment_mailer_prefix"]

          expect(environment_mailer_prefix).to eql("")
        end
      end
    end
  end

  describe("#reset_password_instructions") do
    let(:mail) { described_class.reset_password_instructions(user, "123abc") }

    context "when the email is from the training site" do
      it "includes the environment name in the email subject" do
        ClimateControl.modify CANONICAL_HOSTNAME: "training.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eql("[Training] Reset password instructions")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the environment name in the email subject" do
        ClimateControl.modify CANONICAL_HOSTNAME: "www.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eql("Reset password instructions")
        end
      end
    end
  end

  describe("#first_time_devise_reset_password_instructions") do
    let(:mail) { described_class.first_time_devise_reset_password_instructions(user, "123abc") }

    context "when the email is from the training site" do
      it "includes the environment name in the email subject" do
        ClimateControl.modify CANONICAL_HOSTNAME: "training.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eql("[Training] Action required: RODA password reset")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the environment name in the email subject" do
        ClimateControl.modify CANONICAL_HOSTNAME: "www.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eql("Action required: RODA password reset")
        end
      end
    end
  end
end
