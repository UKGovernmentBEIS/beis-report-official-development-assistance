_query = <<~SQL
  WITH org (id) AS (
    SELECT *
    FROM (VALUES ('d812c501-21b1-412e-9728-a382c83f52fa'::uuid),
                ('fc5126a0-326b-48e3-ac30-daea877afe57'::uuid),
                ('54672da2-74db-47d9-a54a-ea9d0ebc7a79'::uuid),
                ('3e14deb4-1d2f-4386-a703-6d4225324f02'::uuid),
                ('95d15793-2227-47d9-a823-58a799469718'::uuid),
                ('eacb7718-7387-46dd-9cb2-a20fd290858c'::uuid),
                ('c0a63bec-47e7-4937-9922-02a67ba2e5e8'::uuid),
                ('fb4ddc6c-df8f-4d51-a35a-bd168fbd89cc'::uuid),
                ('7fe6df08-1204-4f20-96d5-053c67c63fe0'::uuid),
                ('54204190-4759-4e03-ab00-9e4e751d8535'::uuid),
                ('8cfadf66-3556-4caf-aca6-5b6bced812fc'::uuid),
                ('27546979-7f7d-4c15-af0e-a2c633cb734b'::uuid)
        ) AS values
  )
  select 'activities' as name, COUNT(*) from activities JOIN org ON organisation_id = org.id UNION
  select 'activities_ext' as name, COUNT(*) from activities JOIN org ON organisation_id = org.id UNION
  select 'budgets' as name, COUNT(*) from budgets JOIN org ON providing_organisation_id = org.id UNION
  select 'users' as name, COUNT(*) from users JOIN org ON organisation_id = org.id UNION
  select 'reports' as name, COUNT(*) from reports JOIN org ON organisation_id = org.id UNION
  select 'org_participations' as name, COUNT(*) from org_participations JOIN org ON organisation_id = org.id UNION
  select 'matched_efforts' as name, COUNT(*) from matched_efforts JOIN org ON organisation_id = org.id
SQL

orgs = ["UNIVERSITY OF ULSTER",
  "UK CENTRE FOR ECOLOGY AND HYDROLOGY",
  "THE BRITISH GEOLOGICAL SURVEY",
  "SOAS UNIVERSITY OF LONDON",
  "NIAB",
  "NERC BRITISH ANTARCTIC SURVEY",
  "NERC BRITISH GEOLOGICAL SURVEY",
  "MRC UNIT THE GAMBIA",
  "KTN",
  "INSTUTE FOR ENVIRONMENTAL ANALYTICS",
  "CTR FOR STUDY EQUITY & GOV (HEALTH SYS)",
  "C.A.B. INTERNATIONAL LIMITED"]

orgs.each do |org_name|
  org = Organisation.find_by(name: org_name)
  OrgParticipation.where(organisation: org).destroy_all
  org.destroy
end
