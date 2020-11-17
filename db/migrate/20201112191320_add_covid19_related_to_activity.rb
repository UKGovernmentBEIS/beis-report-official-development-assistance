class AddCovid19RelatedToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :covid19_related, :integer, default: 0
  end
end
