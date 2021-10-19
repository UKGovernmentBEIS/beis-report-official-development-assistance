class RefundsForm
  include Capybara::DSL
  include RSpec::Matchers
  include ActionView::Helpers::NumberHelper

  attr_reader :activity, :financial_quarter, :financial_year, :comment

  def initialize(activity:)
    @activity = activity
  end

  class << self
    include Rails.application.routes.url_helpers
    include Capybara::DSL

    def create(activity:)
      visit organisation_activity_financials_path(
        organisation_id: activity.organisation.id,
        activity_id: activity.id
      )
      click_on I18n.t("page_content.refund.button.create")

      new(activity: activity)
    end
  end

  def complete(value: nil, financial_quarter: nil, financial_year: nil, comment: nil)
    @value = value
    @financial_quarter = financial_quarter
    @financial_year = financial_year
    @comment = comment

    fill_in_value
    fill_in_financial_quarter
    fill_in_financial_year
    fill_in_comment

    click_on(I18n.t("default.button.submit"))
  end

  def value
    return nil if @value.nil?

    -@value.to_d.abs
  end

  def value_with_currency
    number_to_currency(value, unit: "£")
  end

  def financial_quarter_and_year
    FinancialQuarter.new(financial_year, financial_quarter)
  end

  private

  def fill_in_value
    fill_in "refund_form[value]", with: @value
  end

  def fill_in_financial_quarter
    return unless @financial_quarter.present?

    choose @financial_quarter.to_s, name: "refund_form[financial_quarter]"
  end

  def fill_in_financial_year
    return unless @financial_year.present?

    within "select[name=\"refund_form[financial_year]\"]" do
      find("option[value='#{@financial_year}']").select_option
    end
  end

  def fill_in_comment
    fill_in "refund_form[comment]", with: @comment
  end
end
