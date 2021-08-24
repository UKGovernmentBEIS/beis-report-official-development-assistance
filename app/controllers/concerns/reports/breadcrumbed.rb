module Reports
  module Breadcrumbed
    extend ActiveSupport::Concern

    def prepare_default_report_trail(report)
      BreadcrumbContext.new(session).set(type: :report, model: report)

      if report.approved?
        add_breadcrumb "Historic Reports", reports_path(anchor: "historic")
      else
        add_breadcrumb "Current Reports", reports_path
      end

      add_breadcrumb t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report)
    end

    def prepare_default_report_variance_trail(report)
      add_historic_or_current_report_breadcrumb(report)

      add_breadcrumb t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_variance_path(report)
    end

    private

    def add_historic_or_current_report_breadcrumb(report)
      if report.approved?
        add_breadcrumb "Historic Reports", reports_path(anchor: "historic")
      else
        add_breadcrumb "Current Reports", reports_path
      end
    end
  end
end
