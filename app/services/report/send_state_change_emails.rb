class Report
  class SendStateChangeEmails
    attr_reader :report

    def initialize(report)
      @report = report
    end

    def send!
      case report.state
      when "active"
        send_activated
      when "submitted"
        send_submitted
      when "awaiting_changes"
        send_awaiting_changes
      when "approved"
        send_approved
      end
    end

    private

    def send_activated
      send_mail_to_users(:activated)
    end

    def send_submitted
      send_mail_to_users(:submitted, (delivery_partners + service_owners))
    end

    def send_awaiting_changes
      send_mail_to_users(:awaiting_changes)
    end

    def send_approved
      send_mail_to_users(:approved, (delivery_partners + service_owners))
    end

    def send_mail_to_users(action, users = delivery_partners)
      users.each do |user|
        ReportMailer.with(report: report, user: user).send(action).deliver_later
      end
    end

    def delivery_partners
      @report.organisation.users.active
    end

    def service_owners
      Organisation.service_owner.users.active
    end
  end
end
