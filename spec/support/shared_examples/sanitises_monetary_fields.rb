RSpec.shared_examples "sanitises monetary field" do
  context "when a value is passed in" do
    context "and that value contains alphabetical characters" do
      it "sets a value without these characters" do
        attributes = ActionController::Parameters.new(value: "abc 123.00 xyz").permit!
        result = subject.call(attributes: attributes)
        expect(result.object.value).to eq(BigDecimal("123.00"))
      end
    end

    context "and that value contains currency characters" do
      it "sets a value without these characters" do
        attributes = ActionController::Parameters.new(value: "£123.00").permit!
        result = subject.call(attributes: attributes)
        expect(result.object.value).to eq(BigDecimal("123.00"))
      end
    end

    context "and that value contains commas" do
      it "sets a value without these characters" do
        attributes = ActionController::Parameters.new(value: "1,230.90").permit!
        result = subject.call(attributes: attributes)
        expect(result.object.value).to eq(BigDecimal("1230.90"))
      end
    end

    context "and that value contains a single decimal place" do
      it "sets a value to 1 decimal place and omits the trailing zero" do
        attributes = ActionController::Parameters.new(value: "1.1").permit!
        result = subject.call(attributes: attributes)
        expect(result.object.value).to eq(BigDecimal("1.1"))
        expect(result.object.value).to eq(BigDecimal("1.10"))
      end
    end

    context "and that value contains 2 decimal places" do
      it "sets a value to 2 decimal places" do
        attributes = ActionController::Parameters.new(value: "1.11").permit!
        result = subject.call(attributes: attributes)
        expect(result.object.value).to eq(BigDecimal("1.11"))
      end
    end

    context "and that value contains more than 2 decimal places" do
      it "rounds the value back up to 2 decimal places" do
        attributes = ActionController::Parameters.new(value: "1.115").permit!
        result = subject.call(attributes: attributes)
        expect(result.object.value).to eq(BigDecimal("1.12"))
      end
    end
  end
end
