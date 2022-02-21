require "notify/otp_message"

RSpec.describe Notify::OTPMessage do
  subject(:message) { Notify::OTPMessage.new("+447700900000", "123456") }
  let(:fake_client) { spy("Notifications::Client") }

  before do
    allow(message).to receive(:client).and_return(fake_client)
  end

  describe "#deliver" do
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
end
