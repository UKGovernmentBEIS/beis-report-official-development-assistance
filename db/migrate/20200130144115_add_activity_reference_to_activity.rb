class AddActivityReferenceToActivity < ActiveRecord::Migration[6.0]
  def change
    add_reference :activities, :activity, type: :uuid, foreign_key: true
  end
end
