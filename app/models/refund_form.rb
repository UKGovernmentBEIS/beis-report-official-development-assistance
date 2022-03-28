class RefundForm
  include ActiveModel::Model

  attr_accessor :financial_quarter, :financial_year, :report,
    :value, :comment, :parent_activity, :id

  validates :financial_quarter, presence: true
  validates :financial_year, presence: true
  validates :value, presence: true, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :comment, presence: true

  def initialize(params = {})
    @financial_quarter = params[:financial_quarter]
    @financial_year = params[:financial_year]
    @value = params[:value]
    @comment = params[:comment]
    @parent_activity = params[:parent_activity]
    @report = params[:report]
    @id = params[:id]
    @persisted = params[:persisted]
  end

  def attributes
    {
      financial_quarter: financial_quarter,
      financial_year: financial_year,
      value: value,
      comment: comment
    }
  end

  def persisted?
    @persisted.present?
  end
end
