class AddRequiresAdditionalBenefittingCountriesToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :requires_additional_benefitting_countries, :boolean
  end
end
