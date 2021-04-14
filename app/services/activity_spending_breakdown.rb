class ActivitySpendingBreakdown
  def initialize(activity:, report:)
    @activity = activity
    @activity_presenter = ActivityPresenter.new(activity)
    @report = report
  end

  def headers
    combined_hash.keys
  end

  def values
    combined_hash.values
  end

  def combined_hash
    identifiers.merge(metadata)
  end

  def identifiers
    {
      "RODA identifier" => @activity.roda_identifier,
      "BEIS identifier" => @activity.beis_id,
      "Delivery partner identifier" => @activity.delivery_partner_identifier,
    }
  end

  def metadata
    {
      "Title" => @activity_presenter.display_title,
      "Description" => @activity_presenter.description,
      "Programme status" => @activity_presenter.programme_status,
      "ODA eligibility" => @activity_presenter.oda_eligibility,
    }
  end
end
