beis = Organisation.service_owner

gcrf_fund_params = FactoryBot.build(:fund_activity,
  roda_identifier: "GCRF",
  title: "Global Challenges Research Fund (GCRF)",
  organisation: beis).attributes

gcrf_fund = Activity.find_or_create_by(gcrf_fund_params)

newton_fund_params = FactoryBot.build(:fund_activity,
  roda_identifier: "NF",
  title: "Newton Fund",
  organisation: beis).attributes

_newton_fund = Activity.find_or_create_by(newton_fund_params)

ooda_fund_params = FactoryBot.build(:fund_activity,
  roda_identifier: "OODA",
  title: "Other ODA",
  organisation: beis).attributes

_ooda_fund = Activity.find_or_create_by(ooda_fund_params)

ispf_fund_params = FactoryBot.build(:fund_activity,
  roda_identifier: "ISPF",
  title: "International Science Partnerships Fund",
  organisation: beis).attributes

_ispf_fund = Activity.find_or_create_by(ispf_fund_params)

partner_organisation = User.all.find(&:partner_organisation?).organisation

first_programme_params = FactoryBot.build(:programme_activity,
  title: "International Partnerships",
  organisation: beis,
  parent: gcrf_fund,
  extending_organisation: partner_organisation).attributes

programme = Activity.find_or_create_by(first_programme_params)

second_programme_params = FactoryBot.build(:programme_activity,
  title: "Africa Catalyst Programme",
  organisation: beis,
  parent: gcrf_fund,
  extending_organisation: partner_organisation).attributes

Activity.find_or_create_by(second_programme_params)

first_project_params = FactoryBot.build(:project_activity,
  title: "Airbus Flood and Drought",
  organisation: partner_organisation,
  parent: programme,
  extending_organisation: partner_organisation).attributes

first_project = Activity.find_or_create_by(first_project_params)

second_project_params = FactoryBot.build(:project_activity,
  title: "Second Project - no children",
  organisation: partner_organisation,
  parent: programme,
  extending_organisation: partner_organisation).attributes

Activity.find_or_create_by(second_project_params)

third_project_params = FactoryBot.build(:project_activity,
  title: "Third Project - 1 child",
  organisation: partner_organisation,
  parent: programme,
  extending_organisation: partner_organisation).attributes

third_project = Activity.find_or_create_by(third_project_params)

(1..4).each do |i|
  third_party_project_params = FactoryBot.build(:third_party_project_activity,
    title: "Something good #{i}",
    organisation: partner_organisation,
    parent: first_project,
    extending_organisation: partner_organisation).attributes

  Activity.find_or_create_by(third_party_project_params)
end

third_party_project_params = FactoryBot.build(:third_party_project_activity,
  title: "Only child",
  organisation: partner_organisation,
  parent: third_project,
  extending_organisation: partner_organisation).attributes

Activity.find_or_create_by(third_party_project_params)

[
  Activity.fund,
  Activity.programme,
  Activity.project,
  Activity.third_party_project
].each do |set|
  set.each do |activity|
    activity.save!
  end
end

Report.for_activity(first_project).create!(state: :active)
