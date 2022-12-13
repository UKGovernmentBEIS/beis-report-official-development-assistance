class ChangeIspfThemeToIspfThemesArray < ActiveRecord::Migration[6.1]
  def up
    rename_column :activities, :ispf_theme, :ispf_themes
    change_column :activities, :ispf_themes, :integer, array: true, using: "(array[ispf_themes]::integer[])"
  end

  def down
    change_column :activities, :ispf_themes, :integer, default: nil, using: "(ispf_themes[1]::integer)"
    rename_column :activities, :ispf_themes, :ispf_theme
  end
end
