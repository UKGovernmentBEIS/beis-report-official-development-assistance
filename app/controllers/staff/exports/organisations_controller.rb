class Staff::Exports::OrganisationsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  before_action do
    @organisation = Organisation.find(params[:id])
    authorize :export, :show?
  end

  def show
  end

  def transactions
    respond_to do |format|
      format.csv do
        activities = Activity.where(organisation: @organisation)
        export = QuarterlyTransactionExport.new(activities)

        stream_csv_download(filename: "transactions.csv", headers: export.headers) do |csv|
          export.rows.each { |row| csv << row }
        end
      end
    end
  end
end
