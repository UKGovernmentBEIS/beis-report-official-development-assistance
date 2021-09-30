class RemoveAdditionlBenefittingCountriesRequired < ActiveRecord::Migration[6.1]
  def change
    remove_column(:activities, :requires_additional_benefitting_countries, :boolean, if_exists: true)
  end
end
