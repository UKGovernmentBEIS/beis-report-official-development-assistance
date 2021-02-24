class RemoveBeisReports
  def self.execute
    new.execute
  end

  def execute
    unlink_level_ab_transactions_from_reports
    delete_service_owner_reports
  end

  private

  def unlink_level_ab_transactions_from_reports
    Transaction
      .joins(:parent_activity)
      .where(activities: {level: %w[fund programme]})
      .update_all(report_id: nil)
  end

  def delete_service_owner_reports
    Report
      .joins(:organisation)
      .where(organisations: {service_owner: true})
      .delete_all
  end
end
