class ProgrammeToIatiStatus
  STATUS_MAPPING = {
    "delivery" => "2",
    "planned" => "1",
    "agreement_in_place" => "1",
    "open_for_applications" => "1",
    "review" => "1",
    "decided" => "1",
    "spend_in_progress" => "2",
    "finalisation" => "3",
    "completed" => "4",
    "stopped" => "5",
    "cancelled" => "5",
    "paused" => "6",
  }.freeze

  def programme_status_to_iati_status(programme_status)
    return nil if programme_status.blank?
    STATUS_MAPPING[programme_status]
  end
end
