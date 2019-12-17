class AddProviderAndReceiverOrgToTransactons < ActiveRecord::Migration[6.0]
  def change
    add_reference :transactions, :provider, type: :uuid
    add_reference :transactions, :receiver, type: :uuid
  end
end
