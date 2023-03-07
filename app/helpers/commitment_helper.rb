module CommitmentHelper
  def infer_transaction_date_from_activity_attributes(activity)
    return activity.planned_start_date if activity.planned_start_date
    return activity.actual_start_date if activity.actual_start_date

    activity.created_at.to_date
  end
end
