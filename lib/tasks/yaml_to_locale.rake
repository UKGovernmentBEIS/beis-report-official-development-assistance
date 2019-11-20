desc "Extract codes & names from IATI codelists for locale files"
task :yaml_to_locale, [:entity, :type] => [:environment] do |_task, args|
  if [args[:entity], args[:type]].compact.empty?
    abort "Call using `rake yaml_to_locale['entity_name','type']`\n e.g. `rake yaml_to_locale['activity','aid_type']`"
  end
  entity = args[:entity]
  type = args[:type]
  yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/#{entity}/#{type}.yml"))
  data = yaml["data"]
  data.map { |item| puts "#{item["code"].downcase}: \"#{item["name"]}\"" }
end
