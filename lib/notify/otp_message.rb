module Notify
  # Sends an SMS message via Notify.
  # Requires the existence of a NOTIFY_OTP_VERIFICATION_TEMPLATE uuid
  # in the GOV.UK Notify account associated with the client NOTIFY_KEY.
  class OTPMessage
    # @param mobile_number [String] The mobile number to {#deliver} to
    # @param current_otp [String] The six-digit one-time password
    def initialize(mobile_number, current_otp)
      @mobile_number = mobile_number
      @current_otp = current_otp
    end

    # @return A [Notifications::Client:ResponseNotification], see
    #         https://docs.notifications.service.gov.uk/ruby.html#response
    def deliver
      client.send_sms(
        phone_number: @mobile_number,
        template_id: ENV["NOTIFY_OTP_VERIFICATION_TEMPLATE"],
        personalisation: {otp: @current_otp}
      )
    end

    private

    def client
      @client ||= Notifications::Client.new(ENV["NOTIFY_KEY"])
    end
  end
end
