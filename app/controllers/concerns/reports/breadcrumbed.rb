module Reports
  module Breadcrumbed
    extend ActiveSupport::Concern

    def prepare_default_report_trail(report)
      if report.approved?
        add_breadcrumb "Historic Reports", reports_path(anchor: "historic")
      else
        add_breadcrumb "Current Reports", reports_path
      end

      add_breadcrumb t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report)
    end
  end
end
