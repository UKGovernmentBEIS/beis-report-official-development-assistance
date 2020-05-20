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
end
