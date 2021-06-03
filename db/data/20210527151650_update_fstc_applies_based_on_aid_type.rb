# Run me with `rails runner db/data/20210527151650_update_fstc_applies_based_on_aid_type.rb`
require "csv"

aid_types = Codelist.new(type: "aid_type", source: "beis")

aid_type_codes_where_ftsc_applies_should_be_true = aid_types.select { |a| a["ftsc_applies"] == true }.pluck("code")
activities_where_ftsc_applies_is_false_instead_of_true = Activity.where(
  aid_type: aid_type_codes_where_ftsc_applies_should_be_true,
  fstc_applies: false
)

activities_where_ftsc_applies_is_false_instead_of_true.update_all(fstc_applies: true)

aid_type_codes_where_ftsc_applies_should_be_false = aid_types.select { |a| a["ftsc_applies"] == false }.pluck("code")
activities_where_ftsc_applies_is_true_instead_of_false = Activity.where(
  aid_type: aid_type_codes_where_ftsc_applies_should_be_false,
  fstc_applies: true
)

activities_where_ftsc_applies_is_true_instead_of_false.update_all(fstc_applies: false)
