module EmailHelpers
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

  RSpec::Matchers.define :with_personalisations do |expected|
    match do |actual|
      personalisation["unparsed_value"] == expected
    end

    def personalisation
      JSON.parse(email.to_json)["header"].find { |header| header["name"] == "personalisation" }
    end

    def emails
      ActionMailer::Base.deliveries
    end

    def email
      emails.find { |email| email.to == [actual.email] }
    end
  end
end
