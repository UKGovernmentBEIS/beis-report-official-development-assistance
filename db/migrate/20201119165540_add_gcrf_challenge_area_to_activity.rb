class AddGcrfChallengeAreaToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :gcrf_challenge_area, :integer, null: true
  end
end
