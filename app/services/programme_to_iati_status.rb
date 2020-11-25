class ProgrammeToIatiStatus
  STATUS_MAPPING = {
    "01" => "2",
    "02" => "1",
    "03" => "1",
    "04" => "1",
    "05" => "1",
    "06" => "1",
    "07" => "2",
    "08" => "3",
    "09" => "4",
    "10" => "5",
    "11" => "5",
    "12" => "6",
  }.freeze

  def programme_status_to_iati_status(programme_status)
    return nil if programme_status.blank?
    STATUS_MAPPING[programme_status]
  end
end
