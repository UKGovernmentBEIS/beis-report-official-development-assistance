class UpdateAmsGcrfProgrammeParents < ActiveRecord::Migration[6.0]
  def up
    fund = Activity.fund.find_by!(delivery_partner_identifier: "GCRF")

    delivery_partner_identifiers = [
      "AMS-GCRF-Coll-RF-FLAIR",
      "AMS-GCRF-DEL",
      "AMS-GCRF-Coll-RF-NG",
      "AMS-GCRF-Core-Workshops",
      "AMS-GCRF-Coll-RF-SF",
    ]

    Activity.programme.where(delivery_partner_identifier: delivery_partner_identifiers).update_all(parent_id: fund.id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
