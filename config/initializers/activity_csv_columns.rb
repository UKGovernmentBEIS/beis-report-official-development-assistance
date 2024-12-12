ACTIVITY_CSV_COLUMNS = YAML.safe_load_file("#{Rails.root}/config/activity_csv_columns.yml", symbolize_names: true)[:columns].freeze
