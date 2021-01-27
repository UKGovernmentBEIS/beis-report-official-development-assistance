beis = Organisation.find_by(service_owner: true)

gcrf_fund_params = FactoryBot.build(:fund_activity,
  roda_identifier_fragment: "GCRF",
  title: "Global Challenges Research Fund (GCRF)",
  organisation: beis).attributes

gcrf_fund = Activity.find_or_create_by(gcrf_fund_params)

newton_fund_params = FactoryBot.build(:fund_activity,
  roda_identifier_fragment: "NF",
  title: "Newton Fund",
  organisation: beis).attributes

_newton_fund = Activity.find_or_create_by(newton_fund_params)

delivery_partner = User.all.find(&:delivery_partner?).organisation

first_programme_params = FactoryBot.build(:programme_activity,
  title: "International Partnerships",
  organisation: beis,
  parent: gcrf_fund,
  extending_organisation: delivery_partner).attributes

programme = Activity.find_or_create_by(first_programme_params)

second_programme_params = FactoryBot.build(:programme_activity,
  title: "Africa Catalyst Programme",
  organisation: beis,
  parent: gcrf_fund,
  extending_organisation: delivery_partner).attributes

Activity.find_or_create_by(second_programme_params)

first_project_params = FactoryBot.build(:project_activity,
  title: "Airbus Flood and Drought",
  organisation: delivery_partner,
  parent: programme,
  extending_organisation: delivery_partner).attributes

first_project = Activity.find_or_create_by(first_project_params)

second_project_params = FactoryBot.build(:project_activity,
  title: "Second Project - no children",
  organisation: delivery_partner,
  parent: programme,
  extending_organisation: delivery_partner).attributes

Activity.find_or_create_by(second_project_params)

third_project_params = FactoryBot.build(:project_activity,
  title: "Third Project - 1 child",
  organisation: delivery_partner,
  parent: programme,
  extending_organisation: delivery_partner).attributes

third_project = Activity.find_or_create_by(third_project_params)

(1..4).each do |i|
  third_party_project_params = FactoryBot.build(:third_party_project_activity,
    title: "Something good #{i}",
    organisation: delivery_partner,
    parent: first_project,
    extending_organisation: delivery_partner).attributes

  Activity.find_or_create_by(third_party_project_params)
end

third_party_project_params = FactoryBot.build(:third_party_project_activity,
  title: "Only child",
  organisation: delivery_partner,
  parent: third_project,
  extending_organisation: delivery_partner).attributes

Activity.find_or_create_by(third_party_project_params)

[
  Activity.fund,
  Activity.programme,
  Activity.project,
  Activity.third_party_project,
].each do |set|
  set.each do |activity|
    activity.cache_roda_identifier! unless activity.roda_identifier.present?
    activity.save!
  end
end
