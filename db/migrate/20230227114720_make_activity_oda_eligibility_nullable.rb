class MakeActivityOdaEligibilityNullable < ActiveRecord::Migration[6.1]
  def change
    change_column_null :activities, :oda_eligibility, true
  end
end
