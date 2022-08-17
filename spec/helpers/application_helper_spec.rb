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
      span = content_tag :span, " Pear", class: "govuk-visually-hidden"
      accessible_action_link = link_to("Edit#{raw(span)}".html_safe, "pear.com", class: "govuk-link")
      expect(helper.a11y_action_link("Edit", "pear.com", "Pear")).to eql accessible_action_link
    end

    it "merges any supplied css classes" do
      span = content_tag :span, " Pear", class: "govuk-visually-hidden"
      accessible_action_link = link_to("Edit#{raw(span)}".html_safe, "pear.com", class: "pear govuk-link")
      expect(helper.a11y_action_link("Edit", "pear.com", "Pear", ["pear"])).to eql accessible_action_link
    end

    context "when there is no context as a third argument" do
      it "creates the link and doesn't include the span" do
        expect(helper.a11y_action_link("Edit", "pear.com", "")).to eql(link_to("Edit", "pear.com", class: "govuk-link"))
      end
    end
  end

  describe "#link_to_new_tab" do
    it "returns a link with text appended to let the user know it will open in a new tab" do
      expect(helper.link_to_new_tab("Data dictionary", "http://data.dictionary")).to eql(link_to("Data dictionary (opens in new tab)", "http://data.dictionary", class: "govuk-link", target: "_blank", rel: "noreferrer noopener"))
    end
  end

  describe "#environment_name" do
    context "when the hostname is not empty" do
      context "when the hostname is 'www'" do
        it "returns 'production'" do
          ClimateControl.modify CANONICAL_HOSTNAME: "www.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("production")
          end
        end
      end

      context "when the hostname is 'training'" do
        it "returns 'training" do
          ClimateControl.modify CANONICAL_HOSTNAME: "training.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("training")
          end
        end
      end

      context "when the hostname is 'pentest'" do
        it "returns 'training" do
          ClimateControl.modify CANONICAL_HOSTNAME: "pentest.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("training")
          end
        end
      end

      context "when the hostname is 'sandbox'" do
        it "returns 'training" do
          ClimateControl.modify CANONICAL_HOSTNAME: "sandbox.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("sandbox")
          end
        end
      end

      context "when the hostname is 'staging'" do
        it "returns 'training" do
          ClimateControl.modify CANONICAL_HOSTNAME: "staging.report-official-development-assistance.service.gov.uk" do
            expect(helper.environment_name).to eql("staging")
          end
        end
      end

      context "when the hostname is something not listed" do
        it "returns the Rails environment" do
          ClimateControl.modify CANONICAL_HOSTNAME: "something" do
            expect(helper.environment_name).to eql("test")
          end
        end
      end
    end

    context "when the hostname is not set" do
      it "returns the Rails environment" do
        ClimateControl.modify CANONICAL_HOSTNAME: nil do
          expect(helper.environment_name).to eql("test")
        end
      end
    end
  end

  describe "#display_env_name?" do
    context "when the environment_name is one of training, staging, sandbox, or development" do
      it "returns true" do
        %w[training staging sandbox development].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.display_env_name?).to eql(true)
        end
      end
    end

    context "when the environment_name is anything else" do
      it "returns false" do
        ["production", "something", "", nil].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.display_env_name?).to eql(false)
        end
      end
    end
  end

  describe "#environment_mailer_prefix" do
    context "when the environment_name is one of training, staging, sandbox, or development" do
      it "returns the titleised environment name enclosed in square brackets and with a trailing space" do
        %w[training staging sandbox development].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.environment_mailer_prefix).to eql("[#{env_name.titleize}] ")
        end
      end
    end

    context "when the environment_name is anything else" do
      it "returns nil" do
        ["production", "something", "", nil].each do |env_name|
          allow(helper).to receive(:environment_name).and_return(env_name)
          expect(helper.environment_mailer_prefix).to be_nil
        end
      end
    end
  end
end
