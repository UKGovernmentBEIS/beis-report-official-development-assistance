class Staff::LevelB::Budgets::UploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize :level_b, :budget_upload?
  end

  def show
    authorize :level_b, :budget_upload?

    headers = [
      "Type",
      "Financial year",
      "Budget amount",
      "Providing organisation",
      "Providing organisation type",
      "IATI reference",
      "Activity RODA ID",
      "Fund RODA ID",
      "Partner organisation name"
    ]

    stream_csv_download(filename: "Level_B_budgets_upload.csv", headers: headers)
  end
end
