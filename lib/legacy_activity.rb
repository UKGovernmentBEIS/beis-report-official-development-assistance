# require "csv"

class LegacyActivity
  attr_accessor :activity_node_set
  def initialize(activity_node_set:)
    self.activity_node_set = activity_node_set
  end

  def elements
    activity_node_set.elements
  end

  def to_xml
    activity_node_set.to_xml
  end

  def identifier
    identifier_element = elements.detect { |element| element.name.eql?("iati-identifier") }
    return nil unless identifier_element.present?

    identifier_element.children.text
  end
end
