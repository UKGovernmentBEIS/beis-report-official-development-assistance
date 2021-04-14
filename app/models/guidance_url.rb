class GuidanceUrl
  ROOT_PATH = "https://beisodahelp.zendesk.com/hc/en-gb/articles/"

  attr_reader :id

  def initialize(object, field)
    @id = self.class.yaml["guidance_ids"].dig(object, field)
  end

  def to_s
    return "" if id.nil?

    [ROOT_PATH, id].join
  end

  class << self
    def yaml
      @yaml ||= begin
        YAML.safe_load(File.read(Rails.root.join("vendor", "data", "guidance.yml"))).with_indifferent_access
      end
    end
  end
end
