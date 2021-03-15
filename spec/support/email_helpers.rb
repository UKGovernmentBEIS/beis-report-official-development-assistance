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

  RSpec::Matchers.define :be_sent_email do
    match do |actual|
      email = emails.find { |email| email.to == [actual.email] }
      email.present?
    end

    def emails
      ActionMailer::Base.deliveries
    end
  end

  RSpec::Matchers.define :with_subject do |expected|
    match do |actual|
      email.subject == expected
    end

    def emails
      ActionMailer::Base.deliveries
    end

    def email
      emails.find { |email| email.to == [actual.email] }
    end
  end
end
