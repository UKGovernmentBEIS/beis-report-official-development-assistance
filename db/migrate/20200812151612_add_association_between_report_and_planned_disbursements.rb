class AddAssociationBetweenReportAndPlannedDisbursements < ActiveRecord::Migration[6.0]
  def change
    add_reference :planned_disbursements, :report, type: :uuid
  end
end
