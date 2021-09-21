class AdjustmentForm
  include ActiveModel::Model

  attr_accessor :financial_quarter, :financial_year,
    :value, :comment, :parent_activity, :adjustment_type

  validates :financial_quarter, presence: true
  validates :financial_year, presence: true
  validates :value, presence: true
  validates :comment, presence: true
  validates :adjustment_type, presence: true

  def initialize(params = {})
    @financial_quarter = params[:financial_quarter]
    @financial_year = params[:financial_year]
    @value = params[:value]
    @comment = params[:comment]
    @parent_activity = params[:parent_activity]
    @adjustment_type = params[:adjustment_type]
  end
end
