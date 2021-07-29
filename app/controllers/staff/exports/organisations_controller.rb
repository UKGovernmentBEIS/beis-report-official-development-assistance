class Staff::Exports::OrganisationsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  before_action do
    @reporting_organisation = Organisation.service_owner
    @organisation = Organisation.find(params[:id])
    authorize :export, :show?
  end

  def show
    @xml_downloads = Iati::XmlDownload.all_for_organisation(@organisation)
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

  def programme_activities
    @activities = FindProgrammeActivities.new(
      organisation: @organisation,
      user: current_user,
      fund_code: fund_code
    ).call

    render_xml
  end

  def project_activities
    @activities = FindProjectActivities.new(
      organisation: @organisation,
      user: current_user,
      fund_code: fund_code
    ).call.publishable_to_iati

    render_xml
  end

  def third_party_project_activities
    @activities = FindThirdPartyProjectActivities.new(
      organisation: @organisation,
      user: current_user,
      fund_code: fund_code
    ).call.publishable_to_iati

    render_xml
  end

  private

  def fund_code
    Fund.by_short_name(params[:fund]).id if params[:fund]
  end

  def render_xml
    response.headers["Content-Disposition"] = "attachment; filename=\"#{@organisation.iati_reference}.xml\""

    render "staff/exports/organisations/show"
  end
end
