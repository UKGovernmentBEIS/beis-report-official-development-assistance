class Report
  class Export
    def initialize(report:)
      @report = report
      @change_state_column = ChangeStateColumn.new(report: @report)
    end

    def headers
      Row::ACTIVITY_HEADERS.keys +
        @change_state_column.header +
        previous_twelve_quarter_actual_and_refund_headers +
        next_twenty_quarter_forecasts_headers +
        variance_headers
    end

    def rows
      activities.map do |activity|
        Row.new(
          activity: activity,
          change_state: @change_state_column.state_of(activity: activity),
          report_presenter: report_presenter,
          previous_report_quarters: previous_report_quarters,
          following_report_quarters: following_report_quarters,
          actual_quarters: actual_quarters,
          refund_quarters: refund_quarters
        ).call
      end
    end

    def filename
      report_presenter.filename_for_report_download
    end

    private

    attr_reader :report

    def activities
      @activities ||= Activity::ProjectsForReportFinder.new(
        report: report,
        scope: Activity.all
      ).call.sort_by { |a| a.level }
    end

    def actual_quarters
      @actual_quarters ||= Actual::Overview.new(report: report_presenter, include_adjustments: true).all_quarters
    end

    def refund_quarters
      @refund_quarters ||= Refund::Overview.new(report: report_presenter, include_adjustments: true).all_quarters
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

    def previous_twelve_quarter_actual_and_refund_headers
      previous_report_quarters.map { |quarter|
        ["ACT #{quarter}", "REFUND #{quarter}"]
      }.flatten
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
        "Partner organisation identifier" => :delivery_partner_identifier,
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
        "Country partner organisations" => :country_delivery_partners,
        "UK PO named contact" => :uk_dp_named_contact,
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
        "Tied status" => :tied_status_with_code
      }

      VARIANCE_HEADERS = [
        "Comment",
        "Source fund",
        "Partner organisation short name",
        "Link to activity in RODA"
      ]

      def initialize(activity:, report_presenter:, previous_report_quarters:, following_report_quarters:, actual_quarters:, refund_quarters:, change_state:)
        @activity = activity
        @report_presenter = report_presenter
        @previous_report_quarters = previous_report_quarters
        @following_report_quarters = following_report_quarters
        @actual_quarters = actual_quarters
        @refund_quarters = refund_quarters
        @change_state = change_state
      end

      def call
        activity_data +
          @change_state +
          previous_quarter_actuals_and_refunds +
          next_quarter_forecasts +
          variance_data
      end

      def activity_data
        ACTIVITY_HEADERS.map do |_key, value|
          activity_presenter.send(value)
        end
      end

      def previous_quarter_actuals_and_refunds
        previous_report_quarters.map { |quarter|
          [
            actual_value(quarter),
            refund_value(quarter)
          ]
        }.flatten
      end

      def next_quarter_forecasts
        following_report_quarters.map do |quarter|
          value = forecast_quarters.value_for(**quarter)
          "%.2f" % value
        end
      end

      def variance_data
        [
          variance_for_report_financial_quarter,
          activity_presenter.comments_for_report(report_id: report_presenter.id).map(&:body).join("\n"),
          activity_presenter.source_fund&.name,
          activity_presenter.extending_organisation&.beis_organisation_reference,
          activity_presenter.link_to_roda
        ]
      end

      private

      attr_reader :activity, :report_presenter, :previous_report_quarters, :following_report_quarters, :actual_quarters, :refund_quarters

      def activity_presenter
        @activity_presenter ||= ActivityCsvPresenter.new(activity)
      end

      def forecast_quarters
        @forecast_quarters ||= ForecastOverview.new(activity_presenter).snapshot(report_presenter).all_quarters
      end

      def variance_for_report_financial_quarter
        forecast_quarters.value_for(**report_presenter.own_financial_quarter) - actual_quarters.value_for(activity: activity, **report_presenter.own_financial_quarter)
      end

      def actual_value(quarter)
        value = actual_quarters.value_for(activity: activity, **quarter)
        "%.2f" % value
      end

      def refund_value(quarter)
        value = refund_quarters.value_for(activity: activity, **quarter)
        "%.2f" % value
      end
    end

    class ChangeStateColumn
      class UnexpectedActivity < StandardError; end

      def initialize(report:)
        @report = report
      end

      def header
        ["Change state"]
      end

      def state_of(activity:)
        raise ArgumentError, "Activity is not expected for report id #{@report.id}" unless all_activities_for_report.include?(activity.id)
        return ["New"] if all_new_activities.include?(activity.id)
        return ["Changed"] if all_changed_activities.include?(activity.id)
        ["Unchanged"]
      end

      private

      def all_activities_for_report
        @_all_activities_for_report ||= Activity::ProjectsForReportFinder.new(report: @report).call.pluck(:id)
      end

      def all_new_activities
        @_all_new_activities ||= @report.new_activities.pluck(:id)
      end

      def all_changed_activities
        @_all_changed_activities ||= @report.activities_updated.pluck(:id)
      end
    end
  end
end
