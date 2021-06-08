class FieldInference
  Conflict = Class.new(StandardError)

  Field = Struct.new(:name, :value, :allowed)

  Rule = Struct.new(:source, :target) {
    def match?(model)
      model[source.name] == source.value
    end

    def allowed_values
      target.allowed || [target.value]
    end

    def fix?
      target.allowed.nil?
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

  def allowed_values(model, attr_name)
    allowed = rules_for_target(model, attr_name.to_s).map(&:allowed_values)

    if allowed.empty?
      nil
    else
      allowed.compact.reduce(:&)
    end
  end

  def editable?(model, attr_name)
    allowed = allowed_values(model, attr_name)
    allowed.nil? || allowed.size > 1
  end

  def rules_for_source(attr_name, value)
    field = Field.new(attr_name, value)
    @rules.select { |rule| rule.source == field }
  end

  def rules_for_target(model, attr_name)
    @rules.select { |rule| rule.match?(model) && rule.target.name == attr_name }
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

    def restrict(attr_name, values)
      target = Field.new(attr_name.to_s, nil, values)
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

      @parent.rules_for_source(attr_name, value).each do |rule|
        assign(rule.target.name, rule.target.value) if rule.fix?
      end
    end

    def check_for_conflicts(attr_name, value)
      rules = @parent.rules_for_target(@model, attr_name)

      rules.each do |rule|
        next if rule.target.value == value

        raise Conflict, "would change the value of `#{rule.target.name}` " \
          "which is fixed to #{rule.target.value.inspect} because " \
          "`#{rule.source.name}` is #{rule.source.value.inspect}"
      end
    end
  end
end
