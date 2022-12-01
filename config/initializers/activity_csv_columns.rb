ACTIVITY_CSV_COLUMNS = YAML.safe_load(
  File.read("#{Rails.root}/config/activity_csv_columns.yml"),
  symbolize_names: true
)[:columns].freeze
