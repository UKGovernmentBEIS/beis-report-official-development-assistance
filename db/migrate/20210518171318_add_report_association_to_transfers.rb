class AddReportAssociationToTransfers < ActiveRecord::Migration[6.1]
  def change
    add_reference :transfers, :report, type: :uuid
  end
end
