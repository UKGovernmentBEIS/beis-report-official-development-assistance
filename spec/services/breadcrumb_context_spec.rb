require "rails_helper"

RSpec.describe BreadcrumbContext do
  let(:breadcrumb_context) { {} }
  let(:session) { {breadcrumb_context: breadcrumb_context} }
  let(:report) { build(:report) }

  subject { described_class.new(session) }

  describe "#set" do
    it "sets the breadcrumb context" do
      subject.set(type: :report, model: report)

      expect(session[:breadcrumb_context]).to eq({type: :report, model: report})
    end
  end

  context "when the breadcrumb context is set" do
    let(:breadcrumb_context) { {type: :report, model: report} }

    describe "#empty?" do
      it "should return false" do
        expect(subject.empty?).to be false
      end
    end

    describe "#type" do
      it "should return the expected type" do
        expect(subject.type).to eq(:report)
      end
    end

    describe "#model" do
      it "should return the expected model" do
        expect(subject.model).to eq(report)
      end
    end

    describe "#reset!" do
      it "resets the breadcrumb context" do
        subject.reset!

        expect(session[:breadcrumb_context]).to eq({})
      end
    end
  end

  context "when the breadcrumb context is not set" do
    describe "#empty?" do
      it "should return true" do
        expect(subject.empty?).to be true
      end
    end

    describe "#type" do
      it "should return the expected type" do
        expect(subject.type).to eq(nil)
      end
    end

    describe "#model" do
      it "should return the expected model" do
        expect(subject.model).to eq(nil)
      end
    end
  end
end
