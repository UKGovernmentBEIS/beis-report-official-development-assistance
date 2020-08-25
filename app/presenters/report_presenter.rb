# frozen_string_literal: true

class ReportPresenter < SimpleDelegator
  def state
    return if super.blank?
    I18n.t("label.report.state.#{super.downcase}")
  end

  def deadline
    return if super.blank?
    I18n.l(super)
  end

  def financial_quarter_and_year
    return nil if financial_quarter.nil? || financial_year.nil?
    "Q#{financial_quarter} #{financial_year}-#{financial_year + 1}"
  end

  def quarters_to_date_ranges
    next_four_financial_quarters.map! do |quarter|
      quarter = quarter.match(/(\d) (\d{4})/)
      quarter_num, year = quarter[1].to_i, quarter[2].to_i
      quarter_month = case quarter_num
                      when 1
                        "April"
                      when 2
                        "July"
                      when 3
                        "October"
                      when 4
                        "January"
      end
      year = quarter_num == 4 ? year + 1 : year
      Date.parse("1 #{quarter_month} #{year}").all_quarter
    end
  end
end
