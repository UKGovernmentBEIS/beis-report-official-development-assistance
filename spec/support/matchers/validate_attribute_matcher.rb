RSpec::Matchers.define :validate_attribute do |attribute|
  match do |subject|
    validators = subject.class.validators_on(attribute).select { |validator|
      validator.instance_of?(@validator_class)
    }

    validators.present?
  end

  chain :with do |validator|
    @validator = validator
    @validator_class = "#{validator}_validator".camelize.constantize
  end

  description do
    "check that :#{attribute} is being validated using #{@validator_class}"
  end

  failure_message do
    "expected #{attribute} to be validated using #{@validator_class}"
  end

  failure_message_when_negated do
    "expected #{attribute} to not be validated using #{@validator_class}"
  end
end
