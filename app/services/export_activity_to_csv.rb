require "csv"

class ExportActivityToCsv
  attr_accessor :activity

  def initialize(activity:)
    @activity = activity
  end

  def call
    activity_presenter = ActivityPresenter.new(activity)
    [
      activity_presenter.identifier,
      activity_presenter.transparency_identifier,
      activity_presenter.sector,
      activity_presenter.title,
      activity_presenter.description,
      activity_presenter.status,
      activity_presenter.planned_start_date,
      activity_presenter.actual_start_date,
      activity_presenter.planned_end_date,
      activity_presenter.actual_end_date,
      activity_presenter.recipient_region,
      activity_presenter.recipient_country,
      activity_presenter.aid_type,
      activity_presenter.level,
      activity_presenter.link_to_roda,
    ].to_csv
  end
end
