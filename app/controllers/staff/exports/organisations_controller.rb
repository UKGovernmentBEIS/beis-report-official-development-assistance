class Staff::Exports::OrganisationsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  before_action do
    @reporting_organisation = Organisation.service_owner
    @organisation = Organisation.find(params[:id])
  end

  before_action :authorise_xml, only: [:programme_activities, :project_activities, :third_party_project_activities]

  def show
    authorize [:export, @organisation], :show?

    add_breadcrumb(t("breadcrumbs.export.index"), exports_path) if policy([:export, Organisation]).index?
    add_breadcrumb t("breadcrumbs.export.organisation.show", name: @organisation.name), :exports_organisation_path

    @xml_downloads = Iati::XmlDownload.all_for_organisation(@organisation)
  end

  def transactions
    authorize [:export, @organisation], :show_transactions?

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

  def external_income
    authorize [:export, @organisation], :show_external_income?

    fund = Fund.new(params[:fund_id])

    respond_to do |format|
      format.csv do
        export = QuarterlyExternalIncomeExport.new(@organisation, fund)

        stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
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

  def authorise_show
    authorize [:export, @organisation], :show?
  end

  def authorise_xml
    authorize [:export, @organisation], :show_xml?
  end
end
