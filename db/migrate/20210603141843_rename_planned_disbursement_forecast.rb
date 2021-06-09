class RenamePlannedDisbursementForecast < ActiveRecord::Migration[6.1]
  def change
    rename_table :planned_disbursements, :forecasts
    rename_column :forecasts, :planned_disbursement_type, :forecast_type
  end
end
