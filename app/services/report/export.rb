class Report
  class Export
    def initialize(report:)
      @report = report
    end

    def headers
      Row::ACTIVITY_HEADERS.keys +
        previous_twelve_quarter_actuals_headers +
        next_twenty_quarter_forecasts_headers +
        variance_headers
    end

    def rows
      activities.map do |activity|
        Row.new(
          activity: activity,
          report_presenter: report_presenter,
          previous_report_quarters: previous_report_quarters,
          following_report_quarters: following_report_quarters
        ).call
      end
    end

    def filename
      report_presenter.filename_for_report_download
    end

    private

    attr_reader :report

    def activities
      @activities ||= begin
        Activity::ProjectsForReportFinder.new(
          report: report,
          scope: Activity.all
        ).call.sort_by { |a| a.level }
      end
    end

    def report_presenter
      @report_presenter ||= ReportPresenter.new(report)
    end

    def variance_headers
      ["VAR #{report_presenter.financial_quarter_and_year}"] + Row::VARIANCE_HEADERS
    end

    def previous_report_quarters
      @_previous_report_quarters ||= begin
        return [] if report_presenter.own_financial_quarter.nil?

        quarter = report_presenter.own_financial_quarter
        quarter.preceding(11) + [quarter]
      end
    end

    def following_report_quarters
      @_following_report_quarters ||= begin
        return [] if report_presenter.own_financial_quarter.nil?

        quarter = report_presenter.own_financial_quarter
        [quarter] + quarter.following(19)
      end
    end

    def previous_twelve_quarter_actuals_headers
      previous_report_quarters.map { |quarter| "ACT #{quarter}" }
    end

    def next_twenty_quarter_forecasts_headers
      following_report_quarters.map { |quarter| "FC #{quarter}" }
    end

    class Row
      ACTIVITY_HEADERS = {
        "RODA identifier" => :roda_identifier,
        "Transparency identifier" => :transparency_identifier,
        "BEIS identifier" => :beis_identifier,
        "Level" => :level,
        "Delivery partner identifier" => :delivery_partner_identifier,
        "Recipient region" => :recipient_region,
        "Recipient country" => :recipient_country,
        "Intended beneficiaries" => :intended_beneficiaries,
        "Benefitting countries" => :benefitting_countries,
        "Benefitting region" => :benefitting_region,
        "GDI" => :gdi,
        "GCRF Strategic Area" => :gcrf_strategic_area,
        "GCRF Challenge Area" => :gcrf_challenge_area,
        "Fund Pillar" => :fund_pillar,
        "Sustainable Development Goals apply?" => :sustainable_development_goals_apply,
        "SDG 1" => :sdg_1,
        "SDG 2" => :sdg_2,
        "SDG 3" => :sdg_3,
        "Title" => :title,
        "Description" => :description,
        "Aims/Objectives" => :objectives,
        "ODA eligibility" => :oda_eligibility,
        "ODA eligibility lead" => :oda_eligibility_lead,
        "Covid-19 related research" => :covid19_related,
        "Activity status" => :programme_status,
        "Country delivery partners" => :country_delivery_partners,
        "UK DP named contact" => :uk_dp_named_contact,
        "Call open date" => :call_open_date,
        "Call close date" => :call_close_date,
        "Planned start date" => :planned_start_date,
        "Actual start date" => :actual_start_date,
        "Planned end date" => :planned_end_date,
        "Actual end date" => :actual_end_date,
        "Total applications" => :total_applications,
        "Total awards" => :total_awards,
        "Sector" => :sector_with_code,
        "Channel of delivery code" => :channel_of_delivery_code,
        "Flow" => :flow_with_code,
        "Finance type" => :finance_with_code,
        "Aid type" => :aid_type_with_code,
        "Collaboration type" => :collaboration_type,
        "Gender" => :policy_marker_gender,
        "Climate change - Adaptation" => :policy_marker_climate_change_adaptation,
        "Climate change - Mitigation" => :policy_marker_climate_change_mitigation,
        "Biodiversity" => :policy_marker_biodiversity,
        "Desertification" => :policy_marker_desertification,
        "Disability" => :policy_marker_disability,
        "Free Standing Technical Cooperation" => :fstc_applies,
        "Disaster Risk Reduction" => :policy_marker_disaster_risk_reduction,
        "Nutrition policy" => :policy_marker_nutrition,
        "Implementing organisations" => :implementing_organisations,
        "Tied status" => :tied_status_with_code,
      }

      VARIANCE_HEADERS = [
        "Comment",
        "Source fund",
        "Delivery partner short name",
        "Link to activity in RODA",
      ]

      def initialize(activity:, report_presenter:, previous_report_quarters:, following_report_quarters:)
        @activity = activity
        @report_presenter = report_presenter
        @previous_report_quarters = previous_report_quarters
        @following_report_quarters = following_report_quarters
      end

      def call
        activity_data +
          previous_quarter_actuals +
          next_quarter_forecasts +
          variance_data
      end

      private

      attr_reader :activity, :report_presenter, :previous_report_quarters, :following_report_quarters

      def activity_data
        ACTIVITY_HEADERS.map do |_key, value|
          activity_presenter.send(value)
        end
      end

      def previous_quarter_actuals
        actual_quarters = ActualOverview.new(activity: activity_presenter, report: report_presenter).all_quarters

        previous_report_quarters.map do |quarter|
          value = actual_quarters.value_for(**quarter)
          "%.2f" % value
        end
      end

      def next_quarter_forecasts
        forecast_quarters = ForecastOverview.new(activity_presenter).snapshot(report_presenter).all_quarters

        following_report_quarters.map do |quarter|
          value = forecast_quarters.value_for(**quarter)
          "%.2f" % value
        end
      end

      def variance_data
        [
          activity_presenter.variance_for_report_financial_quarter(report: report_presenter),
          activity_presenter.comment_for_report(report_id: report_presenter.id)&.comment,
          activity_presenter.source_fund&.name,
          activity_presenter.extending_organisation&.beis_organisation_reference,
          activity_presenter.link_to_roda,
        ]
      end

      def activity_presenter
        @activity_presenter ||= ActivityCsvPresenter.new(activity)
      end
    end
  end
end
