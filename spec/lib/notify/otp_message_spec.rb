require "notify/otp_message"

RSpec.describe Notify::OTPMessage do
  subject(:message) { Notify::OTPMessage.new("+447700900000", "123456") }
  let(:fake_client) { spy("Notifications::Client") }

  before do
    allow(message).to receive(:client).and_return(fake_client)
  end

  describe "#deliver" do
    context "the GOV.UK Notify request is successful" do
      before { message.deliver }

      it "sends a template ID and personalisation hash to Notify" do
        expect(fake_client).to have_received(:send_sms).with(
          {
            personalisation: {otp: "123456"},
            phone_number: "+447700900000",
            template_id: ENV["NOTIFY_OTP_VERIFICATION_TEMPLATE"]
          }
        )
      end
    end

    context "GOV.UK returns a phone number validation error" do
      let(:govuk_response) { double("Response", code: 400, body: "ValidationError: phone_number Not enough digits") }

      before do
        allow(fake_client).to receive(:send_sms).and_raise(Notifications::Client::BadRequestError.new(govuk_response))

        message.deliver
      end

      it "captures the error and repackages it" do
        expect(message.error).to eql("Not enough digits")
      end
    end

    context "GOV.UK returns any other kind of error" do
      let(:govuk_response) { double("Response", code: 400, body: "ValidationError: everything went wrong") }

      before do
        allow(fake_client).to receive(:send_sms).and_raise(Notifications::Client::BadRequestError.new(govuk_response))
      end

      it "lets the error bubble up" do
        expect { message.deliver }.to raise_error(Notifications::Client::BadRequestError)
      end
    end
  end
end
