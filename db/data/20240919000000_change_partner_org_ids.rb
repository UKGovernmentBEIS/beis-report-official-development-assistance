# Run me with `bin/rails runner db/data/20240919000000_change_partner_org_ids.rb`

class PartnerOrgIdChange
  attr_reader :activity

  def initialize(change:, live_run:)
    @change = change
    @activity = Activity.find_by(roda_identifier: roda_id)
    @live_run = live_run
  end

  def verify_that_activity_has_expected_po_org_id
    if activity.partner_organisation_identifier.strip == existing_po_id
      log(:po_id_matches_expectation)
    else
      log(:po_id_differs)
    end
  end

  def verify_that_new_po_org_id_is_valid
    existing_activities = Activity.where(partner_organisation_identifier: new_po_id)

    if existing_activities.any?
      puts "  the following activities share the new PO ID: "
      existing_activities.each do |existing|
        puts "    Roda ID: #{existing.roda_identifier} | same parent? #{(existing.parent_id == activity.parent_id) ? "YES" : "no"}"
      end
    end
  end

  def rename_po_id
    log(:renaming_po_id)
    return unless @live_run

    activity.partner_organisation_identifier = new_po_id
    activity.save(validate: false)
    activity.reload
    log(:po_id_renamed)
  end

  def log(message)
    case message
    when :activity_found
      puts "Activity found: Roda ID: #{roda_id} | " \
             "Partner Org ID: #{activity.partner_organisation_identifier}"
    when :activity_not_found
      puts "ERROR: no activity found with Roda ID of #{roda_id}" unless activity
    when :po_id_matches_expectation
      puts "  this activity's PO ID matches our expectation"
    when :po_id_differs
      puts "  ERROR: we were expecting Roda ID: #{roda_id} and PO ID #{existing_po_id}"
    when :renaming_po_id
      puts "  renaming PO ID to #{new_po_id}"
    when :po_id_renamed
      puts "  -> Activity #{roda_id} now has PO ID #{activity.partner_organisation_identifier}"
    end
  end

  private

  def new_po_id
    @change.fetch(:new_po_id)
  end

  def roda_id
    @change.fetch(:roda_id)
  end

  def existing_po_id
    @change.fetch(:existing_po_id)
  end
end

class PartnerOrgIdChanger
  def initialize(flag)
    @live_run = flag.match?("live-run")
  end

  def run
    puts "This will be a #{@live_run ? "LIVE RUN" : "dry run"}"
    puts "Number of changes: #{changes.size}"

    changes.each do |change|
      id_change = PartnerOrgIdChange.new(change: change, live_run: @live_run)
      if id_change.activity
        id_change.log(:activity_found)
        id_change.verify_that_activity_has_expected_po_org_id
        id_change.verify_that_new_po_org_id_is_valid
        id_change.rename_po_id
      else
        id_change.log(:activity_not_found)
      end
    end
  end

  def changes
    [
      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-YLZDCUS",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100415',
       new_po_id: 'RaR\100415'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-AABKPMU",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100452',
       new_po_id: 'RaR\100452'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-7BVWXBJ",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100453',
       new_po_id: 'RaR\100453'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-RWBE2HW",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100483',
       new_po_id: 'RaR\100483'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-C7SF7PA",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100494',
       new_po_id: 'RaR\100494'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-7ZX3M2M",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100503',
       new_po_id: 'RaR\100503'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-T3ZLGGN",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100530',
       new_po_id: 'RaR\100530'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-93JQ6KB",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100538',
       new_po_id: 'RaR\100538'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-VCPYD7Y",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100544',
       new_po_id: 'RaR\100544'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-ACU3PVD",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100550',
       new_po_id: 'RaR\100550'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-GRZM5RZ",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100559',
       new_po_id: 'RaR\100559'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-WDDVFA3",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100567',
       new_po_id: 'RaR\100567'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-JQHPTK3",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100569',
       new_po_id: 'RaR\100569'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-ESQWRUS",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100572',
       new_po_id: 'RaR\100572'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-26AESBF",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100574',
       new_po_id: 'RaR\100574'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-J9E4MC5",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100578',
       new_po_id: 'RaR\100578'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-XZ6H95L",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100579',
       new_po_id: 'RaR\100579'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-485PYRU",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100582',
       new_po_id: 'RaR\100582'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-X6MCFGX",
       existing_po_id: 'GCRF-BARAR-Fell22-RaR\100586',
       new_po_id: 'RaR\100586'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-NRGJ62D",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100101",
       new_po_id: 'RaR\100101'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-E63QCMV",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100116",
       new_po_id: 'RaR\100116'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-PUCAY3C",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100166",
       new_po_id: 'RaR\100166'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-476XY79",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100193",
       new_po_id: 'RaR\100193'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-7HXASCQ",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100207",
       new_po_id: 'RaR\100207'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-MQDR7MY",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100212",
       new_po_id: 'RaR\100212'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-NZ64FU8",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100219",
       new_po_id: 'RaR\100219'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-762LQD9",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100224",
       new_po_id: 'RaR\100224'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-JS37ZNN",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100245",
       new_po_id: 'RaR\100245'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-J6ZD6QL",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100249",
       new_po_id: 'RaR\100249'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-Q94NW3V",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100251",
       new_po_id: 'RaR\100251'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-RM45JL7",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100257",
       new_po_id: 'RaR\100257'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-6YQR2VY",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100273",
       new_po_id: 'RaR\100273'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-29YKCP5",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100275",
       new_po_id: 'RaR\100275'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-M5RKFA5",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100277",
       new_po_id: 'RaR\100277'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-68R6J8W",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100278",
       new_po_id: 'RaR\100278'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-6B4N58F",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100281",
       new_po_id: 'RaR\100281'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-QRUNKKT",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100285",
       new_po_id: 'RaR\100285'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-6JRACMX",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100288",
       new_po_id: 'RaR\100288'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-DWZSZGH",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100289",
       new_po_id: 'RaR\100289'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-HDHGUVQ",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100290",
       new_po_id: 'RaR\100290'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-BTSSWW2",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100296",
       new_po_id: 'RaR\100296'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-CC6SYKP",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100300",
       new_po_id: 'RaR\100300'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-3D5J3VD",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100305",
       new_po_id: 'RaR\100305'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-5ES6Q96",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100308",
       new_po_id: 'RaR\100308'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-ELGJGBY",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100310",
       new_po_id: 'RaR\100310'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-JXCBBR7",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100315",
       new_po_id: 'RaR\100315'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-CSGRQ7L",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100317",
       new_po_id: 'RaR\100317'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-GXBQ2S6",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100320",
       new_po_id: 'RaR\100320'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-8PCE9JU",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100349",
       new_po_id: 'RaR\100349'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-U6QXTVQ",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100350",
       new_po_id: 'RaR\100350'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-7ZYRDPV",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100351",
       new_po_id: 'RaR\100351'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-U62E5YC",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100356",
       new_po_id: 'RaR\100356'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-AS3VF5U",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100399",
       new_po_id: 'RaR\100399'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-5ZM69Z5",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100411",
       new_po_id: 'RaR\100411'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-7LH8XA3",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100419",
       new_po_id: 'RaR\100419'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-9K7EMSR",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100421",
       new_po_id: 'RaR\100421'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-UR458XQ",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100423",
       new_po_id: 'RaR\100423'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-PRUZU3Y",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100433",
       new_po_id: 'RaR\100433'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-PX5BQEM",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100434",
       new_po_id: 'RaR\100434'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-T6YKN8G",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100442",
       new_po_id: 'RaR\100442'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-ZME9AQ8",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100445",
       new_po_id: 'RaR\100445'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-CRGCAC9",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100451",
       new_po_id: 'RaR\100451'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-RNMRVWP",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100458",
       new_po_id: 'RaR\100458'},

      {roda_id: "GCRF-BA-R5FBZXE-73R7B48-L9CMQTF",
       existing_po_id: "GCRF-BARAR-Fell22-RaR100477",
       new_po_id: 'RaR\100477'},

      {roda_id: "GCRF-BA-R5FBZXE-QCKLMYQ",
       existing_po_id: 'GCRFGCRFRaR\100084',
       new_po_id: 'RaR\100084'},

      {roda_id: "GCRF-BA-R5FBZXE-H8WQWMF",
       existing_po_id: 'GCRFGCRFRaR\100085',
       new_po_id: 'RaR\100085'},

      {roda_id: "GCRF-BA-R5FBZXE-WAC2SHQ",
       existing_po_id: 'GCRFRaR\100006',
       new_po_id: 'RaR\100006'},

      {roda_id: "GCRF-BA-R5FBZXE-T342TGL",
       existing_po_id: 'GCRFRaR\100076',
       new_po_id: 'RaR\100076'},

      {roda_id: "GCRF-BA-R5FBZXE-NGMGFEW",
       existing_po_id: 'GCRFRaR\100088',
       new_po_id: 'RaR\100088'},

      {roda_id: "GCRF-BA-R5FBZXE-NTZN6KP",
       existing_po_id: 'GCRFRaR\100089',
       new_po_id: 'RaR\100089'},

      {roda_id: "GCRF-BA-R5FBZXE-C4WGXK2",
       existing_po_id: 'GCRFRaR\100095',
       new_po_id: 'RaR\100095'},

      {roda_id: "GCRF-BA-R5FBZXE-UXCL52E",
       existing_po_id: 'GCRFRaR\100096',
       new_po_id: 'RaR\100096'},

      {roda_id: "GCRF-BA-R5FBZXE-RB5N96T",
       existing_po_id: 'GCRFRaR\100107',
       new_po_id: 'RaR\100107'},

      {roda_id: "GCRF-BA-R5FBZXE-FJB9MP3",
       existing_po_id: 'GCRFRaR\100118',
       new_po_id: 'RaR\100118'},

      {roda_id: "GCRF-BA-R5FBZXE-FQDTTWS",
       existing_po_id: 'GCRFRaR\100128',
       new_po_id: 'RaR\100128'},

      {roda_id: "GCRF-BA-R5FBZXE-6LLK578",
       existing_po_id: 'GCRFRaR\100132',
       new_po_id: 'RaR\100132'},

      {roda_id: "GCRF-BA-R5FBZXE-ZL9G4NC",
       existing_po_id: 'GCRFRaR\100149',
       new_po_id: 'RaR\100149'},

      {roda_id: "GCRF-BA-R5FBZXE-HD4ZD6U",
       existing_po_id: 'GCRFRaR\100167',
       new_po_id: 'RaR\100167'},

      {roda_id: "GCRF-BA-R5FBZXE-RRSZFL7",
       existing_po_id: 'GCRFRaR\100168',
       new_po_id: 'RaR\100168'},

      {roda_id: "GCRF-BA-R5FBZXE-7XJMVPD",
       existing_po_id: 'GCRFRaR\100180',
       new_po_id: 'RaR\100180'},

      {roda_id: "GCRF-BA-R5FBZXE-VZR2RX9",
       existing_po_id: 'GCRFRaR\100184',
       new_po_id: 'RaR\100184'},

      {roda_id: "GCRF-BA-R5FBZXE-JUESKL7",
       existing_po_id: 'GCRFRaR\100188',
       new_po_id: 'RaR\100188'},

      {roda_id: "GCRF-BA-R5FBZXE-WLQE3XD",
       existing_po_id: 'GCRFRaR\100190',
       new_po_id: 'RaR\100190'},

      {roda_id: "GCRF-BA-R5FBZXE-LV4ZDJQ",
       existing_po_id: 'GCRFRaR\100202',
       new_po_id: 'RaR\100202'},

      {roda_id: "GCRF-BA-R5FBZXE-26BJAFM",
       existing_po_id: 'GCRFRaR\100204',
       new_po_id: 'RaR\100204'},

      {roda_id: "GCRF-BA-R5FBZXE-7UESF7U",
       existing_po_id: 'GCRFRaR\100209',
       new_po_id: 'RaR\100209'},

      {roda_id: "GCRF-BA-R5FBZXE-UJ2FW9S",
       existing_po_id: 'GCRFRaR\100215',
       new_po_id: 'RaR\100215'},

      {roda_id: "GCRF-BA-R5FBZXE-LAAUJDX",
       existing_po_id: 'GCRFRaR\100226',
       new_po_id: 'RaR\100226'},

      {roda_id: "GCRF-BA-R5FBZXE-AWG4MGE",
       existing_po_id: 'GCRFRaR\100228',
       new_po_id: 'RaR\100228'},

      {roda_id: "GCRF-BA-R5FBZXE-DEWY9CS",
       existing_po_id: 'GCRFRaR\100232',
       new_po_id: 'RaR\100232'},

      {roda_id: "GCRF-BA-R5FBZXE-FT8VVQ5",
       existing_po_id: 'GCRFRaR\100233',
       new_po_id: 'RaR\100233'},

      {roda_id: "GCRF-BA-R5FBZXE-LY2354D",
       existing_po_id: 'GCRFRaR\100239',
       new_po_id: 'RaR\100239'},

      {roda_id: "GCRF-BA-R5FBZXE-TV39XG3",
       existing_po_id: 'GCRFRaR\100242',
       new_po_id: 'RaR\100242'},

      {roda_id: "GCRF-BA-R5FBZXE-AXJZTT2",
       existing_po_id: 'GCRFRaR\100244',
       new_po_id: 'RaR\100244'}

    ]
  end
end

usage = "Include either '--dry-run' for a preview or '--live-run' to make changes"
abort usage unless ["--dry-run", "--live-run"].include?(ARGV.first)

PartnerOrgIdChanger.new(ARGV.first).run
