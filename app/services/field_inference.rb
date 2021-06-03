class FieldInference
  Field = Struct.new(:name, :value)

  Rule = Struct.new(:source, :target) {
    def forbit_edit?(model, attr_name)
      model[source.name] == source.value
    end
  }

  def initialize
    @rules = []
  end

  def on(attr_name, value)
    Selector.new(@rules, attr_name, value)
  end

  def assign(model, attr_name, value)
    Updater.new(@rules, model).assign(attr_name.to_s, value)
  end

  def editable?(model, attr_name)
    @rules
      .select { |rule| rule.target.name == attr_name.to_s }
      .none? { |rule| rule.forbit_edit?(model, attr_name) }
  end

  class Selector
    def initialize(rules, attr_name, value)
      @rules = rules
      @source = Field.new(attr_name.to_s, value)
    end

    def fix(attr_name, value)
      target = Field.new(attr_name.to_s, value)
      @rules << Rule.new(@source, target)
    end
  end

  class Updater
    def initialize(rules, model)
      @rules = rules
      @model = model
    end

    def assign(attr_name, value)
      @model[attr_name] = value
      rules_for_source(attr_name, value).each { |rule| assign(*rule.target) }
    end

    def rules_for_source(attr_name, value)
      field = Field.new(attr_name, value)
      @rules.select { |rule| rule.source == field }
    end
  end
end
