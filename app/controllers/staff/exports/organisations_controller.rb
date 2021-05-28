class Staff::Exports::OrganisationsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  after_action :verify_authorized, except: [:show, :transactions]

  def show
    @organisation = organisation
  end

  def transactions
    respond_to do |format|
      format.csv do
        activities = Activity.where(organisation: organisation)
        export = QuarterlyTransactionExport.new(activities)

        stream_csv_download(filename: "transactions.csv", headers: export.headers) do |csv|
          export.rows.each { |row| csv << row }
        end
      end
    end
  end

  private def organisation
    @_organisation ||= Organisation.find(params[:id])
  end
end
