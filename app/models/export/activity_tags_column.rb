class Export::ActivityTagsColumn
  def initialize(activities:)
    @activities = activities
  end

  def headers
    ["Tags"]
  end

  def rows
    return {} if @activities.nil?

    @activities.pluck(:id, :tags).map do |id, tag_codes|
      tags = tag_codes&.map { |tag_code| codelist.find_item_by_code(tag_code)["description"] }&.join("|")

      [id, [tags]]
    end.to_h
  end

  private

  def codelist
    @codelist ||= Codelist.new(type: "tags", source: "beis")
  end
end
