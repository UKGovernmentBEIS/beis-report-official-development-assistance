require "iati_validator/xml"

RSpec.describe "IATIValidator::XML#valid?" do
  subject { IATIValidator::XML.new(xml).valid? }

  context "the xml is blank" do
    let(:xml) { "" }
    it { is_expected.to be false }
  end

  context "the xml contains a control code" do
    let(:xml) { File.read("#{Rails.root}/spec/fixtures/iati_xml/minimal.xml").sub("REPLACE ME", "\u0002") }
    it { is_expected.to be false }
  end

  context "the xml is valid" do
    let(:xml) { File.read("#{Rails.root}/spec/fixtures/iati_xml/minimal.xml") }
    it { is_expected.to be true }
  end

  describe "the IATI tests (run with '--tag full_iati_test')", full_iati_test: true do
    before(:all) do
      `git clone https://github.com/IATI/IATI-Schemas tmp/IATI-Schemas`
      `cd tmp/IATI-Schemas; git checkout version-2.03`
    end

    describe "the IATI testcases that should pass" do
      Dir.glob("tmp/IATI-Schemas/tests/*-tests/should-pass/**/*.xml").each do |filename|
        context "#{filename} should pass" do
          let(:xml) { File.read(filename) }
          it { is_expected.to be true }
        end
      end
    end

    describe "the IATI testcases that should fail" do
      Dir.glob("tmp/IATI-Schemas/tests/*-tests/should-fail/**/*.xml").each do |filename|
        context "#{filename} should fail" do
          let(:xml) { File.read(filename) }
          it { is_expected.to be false }
        end
      end
    end
  end
end
