module EmailHelpers
  def stub_welcome_email_delivery
    welcome_email_delivery = instance_double(ActionMailer::MessageDelivery)
    allow(UserMailer).to receive(:welcome)
      .and_return(welcome_email_delivery)
    allow(welcome_email_delivery).to receive(:deliver_later)
  end

  def expect_welcome_email_delivery(user: nil)
    welcome_email_delivery = instance_double(ActionMailer::MessageDelivery)
    if user
      expect(UserMailer).to receive(:welcome)
        .with(user)
        .and_return(welcome_email_delivery)
    else
      expect(UserMailer).to receive(:welcome)
        .and_return(welcome_email_delivery)
    end
    expect(welcome_email_delivery).to receive(:deliver_later)
  end
end
