# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#l" do
    it "allows nil to be passed to `localize` without blowing up" do
      expect(helper.l(nil)).to eq(nil)
    end

    it "localises dates as expected" do
      expect(helper.l(Date.today)).to eq(Date.today.strftime("%-d %b %Y"))
    end
  end

  describe "#navigation_item_class" do
    let(:subject) { helper.navigation_item_class("some_path") }

    before do
      allow(helper).to receive(:current_page?).and_return true
    end

    it "returns the active navigation item class" do
      expect(subject).to eql "govuk-header__navigation-item govuk-header__navigation-item--active"
    end
  end

  describe "#a11y_action_link" do
    it "gives action links more context available to a screen reader" do
      accessible_action_link = "<a class=\"govuk-link\" href=\"pear.com\">Edit<span class=\"govuk-visually-hidden\"> Pear</span></a>"
      expect(helper.a11y_action_link("Edit", "pear.com", "Pear")).to eql accessible_action_link
    end

    it "merges any supplied css classes" do
      accessible_action_link = "<a class=\"pear govuk-link\" href=\"pear.com\">Edit<span class=\"govuk-visually-hidden\"> Pear</span></a>"
      expect(helper.a11y_action_link("Edit", "pear.com", "Pear", ["pear"])).to eql accessible_action_link
    end

    context "when there is no context as a third argument" do
      it "creates the link and doesn't include the span" do
        expect(helper.a11y_action_link("Edit", "pear.com", "")).to eql(link_to("Edit", "pear.com", class: "govuk-link"))
      end
    end

    context "with malicious user input in the text" do
      it "escapes the text" do
        malicious_text = "</a><script>alert('hack')</script>Bobby Tables"
        accessible_action_link = "<a class=\"govuk-link\" href=\"pear.com\">&lt;/a&gt;&lt;script&gt;alert(&#39;hack&#39;)&lt;/script&gt;Bobby Tables<span class=\"govuk-visually-hidden\"> Pear</span></a>"
        expect(helper.a11y_action_link(malicious_text, "pear.com", "Pear")).to eql accessible_action_link
      end
    end

    context "with malicious user input in the context" do
      it "escapes the context" do
        malicious_context = "</a><script>alert('hack')</script>Bobby Tables"
        accessible_action_link = "<a class=\"govuk-link\" href=\"pear.com\">Pear<span class=\"govuk-visually-hidden\"> &lt;/a&gt;&lt;script&gt;alert(&#39;hack&#39;)&lt;/script&gt;Bobby Tables</span></a>"
        expect(helper.a11y_action_link("Pear", "pear.com", malicious_context)).to eql accessible_action_link
      end
    end
  end

  describe "#link_to_new_tab" do
    it "returns a link with text appended to let the user know it will open in a new tab" do
      expect(helper.link_to_new_tab("Data dictionary", "http://data.dictionary")).to eql(link_to("Data dictionary (opens in new tab)", "http://data.dictionary", class: "govuk-link", target: "_blank", rel: "noreferrer noopener"))
    end
  end

  describe "#environment_name" do
    context "when the domain is not empty" do
      context "when the domain is 'https://www'" do
        it "returns 'production'" do
          ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("production")
          end
        end
      end

      context "when the domain is 'https://training'" do
        it "returns 'training'" do
          ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("training")
          end
        end
      end

      context "when the domain is 'https://sandbox'" do
        it "returns 'sandbox'" do
          ClimateControl.modify DOMAIN: "sandbox.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("sandbox")
          end
        end
      end

      context "when the domain is 'https://staging'" do
        it "returns 'staging'" do
          ClimateControl.modify DOMAIN: "https://staging.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("staging")
          end
        end
      end

      context "when the domain is 'https://dev'" do
        it "returns 'dev'" do
          ClimateControl.modify DOMAIN: "https://dev.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("dev")
          end
        end
      end

      context "when the domain is something not listed" do
        it "returns the Rails environment" do
          ClimateControl.modify DOMAIN: "https://something" do
            expect(helper.environment_name).to eql("test")
          end
        end
      end
    end

    context "when the domain is not set" do
      it "returns the Rails environment" do
        ClimateControl.modify DOMAIN: nil do
          expect(helper.environment_name).to eql("test")
        end
      end
    end
  end

  describe "#display_env_name?" do
    context "when the environment_name is one of dev, development, sandbox, staging, or training" do
      it "returns true" do
        %w[dev development sandbox staging training].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.display_env_name?).to be(true)
        end
      end
    end

    context "when the environment_name is anything else" do
      it "returns false" do
        ["production", "something", "", nil].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.display_env_name?).to be(false)
        end
      end
    end
  end

  describe "#environment_mailer_prefix" do
    context "when the environment_name is one of dev, development, sandbox, staging, or training" do
      it "returns the titleised environment name enclosed in square brackets and with a trailing space" do
        %w[dev development sandbox staging training].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.environment_mailer_prefix).to eql("[#{env_name.titleize}] ")
        end
      end
    end

    context "when the environment_name is anything else" do
      it "returns an empty string" do
        ["production", "something", "", nil].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.environment_mailer_prefix).to eql("")
        end
      end
    end
  end
end
