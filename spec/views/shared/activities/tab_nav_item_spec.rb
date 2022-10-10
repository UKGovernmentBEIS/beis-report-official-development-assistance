RSpec.describe "staff/shared/activities/_tab_nav_item" do
  subject do
    render partial: "staff/shared/activities/tab_nav_item", locals: {tab: tab, path: path, "@tab_name": tab_name}
    Capybara.string(rendered)
  end

  let(:path) { "https://example.com" }

  describe "controller name matches the current tab" do
    let(:tab_name) { "details" }
    let(:tab) { "details" }

    it "is rendered correctly" do
      expect(subject).to have_css("li.govuk-tabs__list-item--selected")

      within "a.govuk-tabs__tab" do
        expect(subject).to have_link(path)
        expect(subject["aria-selected"]).to be_truthy
      end
    end
  end

  describe "controller name doesn't match the current tab" do
    let(:tab_name) { "another_tab" }
    let(:tab) { "details" }

    it "is rendered correctly" do
      expect(subject).to have_no_css("li.govuk-tabs__list-item--selected")

      within "a.govuk-tabs__tab" do
        expect(subject).to have_link(path)
        expect(subject["aria-selected"]).to be_falsey
      end
    end
  end
end
