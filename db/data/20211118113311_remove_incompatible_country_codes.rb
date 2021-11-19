# Run me with `rails runner db/data/20211118113311_remove_incompatible_country_codes.rb`
#
INCOMPATIBLE_COUNTRY_CODES = ["CH", "A region on IATI code 88"]

def get_all_affected_activities(code)
  Activity.where("? = ANY(benefitting_countries)", code)
end

def remove_incompatible_country_codes(affected_activities, code)
  affected_activities.each do |activity|
    puts "Removing code #{code} from activity #{activity.id}"
    benefitting_countries = activity.benefitting_countries.reject { |country_code| country_code == code }
    activity.benefitting_countries = benefitting_countries
    activity.save!(validate: false)
  end
end

INCOMPATIBLE_COUNTRY_CODES.each { |code| remove_incompatible_country_codes(get_all_affected_activities(code), code) }
