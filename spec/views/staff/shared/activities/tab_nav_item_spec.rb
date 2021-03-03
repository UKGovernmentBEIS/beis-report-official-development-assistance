RSpec.describe "staff/shared/activities/_tab_nav_item" do
  before do
    allow(controller).to receive(:controller_name).and_return(controller_name)
  end

  subject do
    render partial: "staff/shared/activities/tab_nav_item", locals: {tab: tab, path: path}
    Capybara.string(rendered)
  end

  let(:path) { "https://example.com" }

  describe "controller name matches the current tab" do
    let(:controller_name) { "activity_details" }
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
    let(:controller_name) { "another_controller" }
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
