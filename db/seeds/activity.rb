beis = Organisation.find_by(service_owner: true)
activity_params = FactoryBot.build(:activity, title: "GCRF", organisation: beis).attributes
Activity.find_or_create_by(activity_params)
