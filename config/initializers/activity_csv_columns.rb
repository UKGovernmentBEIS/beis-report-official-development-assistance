ACTIVITY_CSV_COLUMNS = YAML.safe_load(
  File.read("#{Rails.root}/config/activity_csv_columns.yml"),
  symbolize_names: true
)[:columns].freeze

level_b_non_oda_attributes = []
level_b_oda_attributes = []
level_c_d_non_oda_attributes = []
level_c_d_oda_attributes = []

ACTIVITY_CSV_COLUMNS.each do |attribute, column|
  level_b_non_oda_attributes << attribute if column.dig(:inclusion, :level_b, :ispf_non_oda)
  level_b_oda_attributes << attribute if column.dig(:inclusion, :level_b, :ispf_oda)
  level_c_d_non_oda_attributes << attribute if column.dig(:inclusion, :level_c_d, :ispf_non_oda)
  level_c_d_oda_attributes << attribute if column.dig(:inclusion, :level_c_d, :ispf_oda)
end

INVALID_LEVEL_B_ISPF_NON_ODA_ATTRIBUTES = (level_b_oda_attributes - level_b_non_oda_attributes).freeze
INVALID_LEVEL_C_D_ISPF_NON_ODA_ATTRIBUTES = (level_c_d_oda_attributes - level_c_d_non_oda_attributes).freeze
