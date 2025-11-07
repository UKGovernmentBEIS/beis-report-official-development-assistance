# Run me with `rails runner db/data/20250626105226_change_partner_org_ids.rb`
# rubocop:disable Lint/UnreachableCode

changes = [
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-PGYD5SK", new_partner_organisation_id: "BB/Z514317/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-TQAJQSC", new_partner_organisation_id: "BB/Z514329/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-WPQ46N2", new_partner_organisation_id: "BB/Y51388X/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-AXYREAE", new_partner_organisation_id: "BB/Y513921/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-WAPCJ3U", new_partner_organisation_id: "BB/Y513933/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-YTZDA5T", new_partner_organisation_id: "BB/Y513891/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-J2HJUAT", new_partner_organisation_id: "BB/Y514019/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-MUA8Z6W", new_partner_organisation_id: "BB/Y513994/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-DLG7KRZ", new_partner_organisation_id: "BB/Y513970/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-SG3ENSC", new_partner_organisation_id: "BB/Y51391X/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-CK6BCHU", new_partner_organisation_id: "BB/Y513878/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-BQ887GA", new_partner_organisation_id: "BB/Y513842/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-FJUHWAN", new_partner_organisation_id: "BB/Y513817/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-2EZTMMB", new_partner_organisation_id: "BB/Y513805/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-PGE976X", new_partner_organisation_id: "BB/Z514305/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-8DZ5WCP", new_partner_organisation_id: "BB/Y513969/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-WMBL4QW", new_partner_organisation_id: "BB/Y513908/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-5M9ALMM", new_partner_organisation_id: "BB/Y513866/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-AJGNENB", new_partner_organisation_id: "BB/Y514020/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-6RAUDCG", new_partner_organisation_id: "BB/Y513957/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-JCQSSEC", new_partner_organisation_id: "BB/Y513982/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-VSWHRB9", new_partner_organisation_id: "BB/Y514007/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-3QS2TTE", new_partner_organisation_id: "BB/Y513945/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-8A86THC", new_partner_organisation_id: "BB/Y514044/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-W3KAXN9", new_partner_organisation_id: "BB/Y513829/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-N84VWWY", new_partner_organisation_id: "BB/Y513763/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-JR7SZWB", new_partner_organisation_id: "BB/Y513787/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-KWNTRA9", new_partner_organisation_id: "BB/Y513799/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-9LUMKHZ", new_partner_organisation_id: "BB/Y514032/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-HAE33XP", new_partner_organisation_id: "BB/Y513830/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-J5BNYC6", new_partner_organisation_id: "BB/Y514056/1"},
  {roda_id: "NODA-ISPF-BBSRC-Y29QRFJ-W6HY3U9-SPAK5UF", new_partner_organisation_id: "BB/Y513854/1"}
]

ActiveRecord::Base.transaction do
  raise "This was run in the Rails console on prod to avoid the need for a release; it should not be run again"

  changes.each do |change|
    activity = Activity.find_by!(roda_identifier: change.fetch(:roda_id))
    puts "BEFORE: Activity #{activity.id} initially has partner organisation identifier: #{activity.partner_organisation_identifier}"

    activity.partner_organisation_identifier = change.fetch(:new_partner_organisation_id)
    activity.save!
    activity.reload

    puts "AFTER: Activity #{activity.id} now has partner organisation identifier: #{activity.partner_organisation_identifier}"
  end
end

# rubocop:enable Lint/UnreachableCode
