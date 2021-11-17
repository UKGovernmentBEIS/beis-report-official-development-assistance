FactoryBot.define do
  factory :unique_implementing_org, class: "UniqueImplementingOrganisation" do
    name { "UKRI" }
    reference
    organisation_type { "10" }
    legacy_names { ["UK Research and Innovation", "UK Research & Innovation"] }
  end
end
