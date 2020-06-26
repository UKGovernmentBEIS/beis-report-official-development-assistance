beis = Organisation.find_by(service_owner: true)

fund_params = FactoryBot.build(:fund_activity,
  title: "GCRF",
  organisation: beis).attributes

fund = Activity.find_or_create_by(fund_params)

delivery_partner = Organisation.find_by!(service_owner: false)

first_programme_params = FactoryBot.build(:programme_activity,
  title: "International Partnerships",
  organisation: beis,
  parent: fund,
  extending_organisation: delivery_partner).attributes

programme = Activity.find_or_create_by(first_programme_params)

second_programme_params = FactoryBot.build(:programme_activity,
  title: "Africa Catalyst Programme",
  organisation: beis,
  parent: fund,
  extending_organisation: delivery_partner).attributes

Activity.find_or_create_by(second_programme_params)

project_params = FactoryBot.build(:project_activity,
  title: "Airbus Flood and Drought",
  organisation: delivery_partner,
  parent: programme,
  extending_organisation: delivery_partner).attributes

Activity.find_or_create_by(project_params)
