class FieldInference
  Conflict = Class.new(StandardError)

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
    Updater.new(self, model).assign(attr_name.to_s, value)
  rescue Conflict => conflict
    raise Conflict, "Cannot set `#{attr_name}` to #{value.inspect}: #{conflict.message}"
  end

  def editable?(model, attr_name)
    rules_for_target(attr_name).none? { |rule| rule.forbit_edit?(model, attr_name) }
  end

  def rules_for_source(attr_name, value)
    field = Field.new(attr_name, value)
    @rules.select { |rule| rule.source == field }
  end

  def rules_for_target(attr_name)
    @rules.select { |rule| rule.target.name == attr_name.to_s }
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
    def initialize(parent, model)
      @parent = parent
      @model = model
    end

    def assign(attr_name, value)
      check_for_conflicts(attr_name, value)
      @model[attr_name] = value
      @parent.rules_for_source(attr_name, value).each { |rule| assign(*rule.target) }
    end

    def check_for_conflicts(attr_name, value)
      rules = @parent.rules_for_target(attr_name).reject { |r| r.target.value == value }

      rules.each do |rule|
        next unless @model[rule.source.name] == rule.source.value

        raise Conflict, "would change the value of `#{rule.target.name}` " \
          "which is fixed to #{rule.target.value.inspect} because " \
          "`#{rule.source.name}` is #{rule.source.value.inspect}"
      end
    end
  end
end
