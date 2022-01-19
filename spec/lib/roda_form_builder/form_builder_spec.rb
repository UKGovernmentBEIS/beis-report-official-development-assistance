require "rails_helper"

class TestHelper < ActionView::Base; end

RSpec.describe RodaFormBuilder::FormBuilder do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(nil), {}, nil) }
  let(:resource) { build(:project_activity) }
  let(:builder) { described_class.new :activity, resource, helper, {} }
  let(:guidance) { double("GuidanceUrl", to_s: url) }

  before do
    expect(GuidanceUrl).to receive(:new).with(:activity, field_name).and_return(guidance)
  end

  [
    :govuk_text_field,
    :govuk_phone_field,
    :govuk_email_field,
    :govuk_password_field,
    :govuk_url_field,
    :govuk_number_field,
    :govuk_text_area
  ].each do |field|
    describe "##{field}" do
      let(:field_name) { :title }
      let(:output) do
        builder.send(field, :title)
      end

      context "when guidance exists for the field" do
        let(:url) { "https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005350001" }

        it "shows a guidance link" do
          expect(output).to include("For help responding to this question, refer to the")
          expect(output).to include("guidance (opens in new tab)")
          expect(output).to include(url)
        end
      end

      context "when guidance does not exist for the field" do
        let(:url) { "" }

        it "does not show a guidance link" do
          expect(output).to_not include("For help responding to this question, refer to the")
        end
      end
    end
  end

  [
    :govuk_collection_select,
    :govuk_collection_radio_buttons,
    :govuk_collection_check_boxes
  ].each do |field|
    let(:field_name) { :title }
    let(:collection) do
      [
        OpenStruct.new(name: "Foo", code: 1),
        OpenStruct.new(name: "Bar", code: 2)
      ]
    end
    let(:output) do
      builder.send(field, :title, collection, :name, :code)
    end

    context "when guidance exists for the field" do
      let(:url) { "https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005350001" }

      it "shows a guidance link" do
        expect(output).to include("For help responding to this question, refer to the")
        expect(output).to include("guidance (opens in new tab)")
        expect(output).to include(url)
      end
    end

    context "when guidance does not exist for the field" do
      let(:url) { "" }

      it "does not show a guidance link" do
        expect(output).to_not include("For help responding to this question, refer to the")
      end
    end
  end

  describe "#govuk_date_field" do
    let(:field_name) { :call_open_date }
    let(:output) do
      builder.govuk_date_field(field_name)
    end

    context "when guidance exists for the field" do
      let(:url) { "https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005350001" }

      it "shows a guidance link" do
        expect(output).to include("For help responding to this question, refer to the")
        expect(output).to include("guidance (opens in new tab)")
        expect(output).to include(url)
      end
    end

    context "when guidance does not exist for the field" do
      let(:url) { "" }

      it "does not show a guidance link" do
        expect(output).to_not include("For help responding to this question, refer to the")
      end
    end
  end
end
