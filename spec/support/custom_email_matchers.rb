module CustomEmailMatchers
  class HaveRecievedEmail
    def matches?(user)
      @user = user
      email_sent? && has_subject? && has_personalisations?
    end

    def with_subject(subject)
      @expected_subject = subject
      self
    end

    def with_personalisations(personalisations)
      @expected_personalisations = personalisations
      self
    end

    def email
      @email ||= emails.find { |email| email.to == [@user.email] }
    end

    def emails
      ActionMailer::Base.deliveries
    end

    def email_sent?
      email.present?
    end

    def has_subject?
      return true unless @expected_subject

      email.subject == @expected_subject
    end

    def has_personalisations?
      return true unless @expected_personalisations

      personalisation == @expected_personalisations
    end

    def personalisation
      JSON.parse(email.to_json)["header"].find { |header| header["name"] == "personalisation" }["unparsed_value"]
    end

    def failure_message
      message = "Expected #{@user.email} to receive email"
      message << " with subject #{@expected_subject}, but was #{@email.subject}" if @expected_subject
      message << " with personalisations #{@expected_personalisations}, but was #{personalisation}" if @expected_personalisations
      message
    end
  end

  def have_received_email
    HaveRecievedEmail.new
  end
end
