# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Users can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:organisation) { create(:organisation) }

    context "when the user is a fund manager" do
      before { authenticate!(user: create(:fund_manager, organisation: organisation)) }

      context "when the activity is a fund activity" do
        let(:activity) { create(:fund_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end

      context "when the activity is a programme activity" do
        let(:activity) { create(:programme_activity, organisation: organisation, identifier: "IND-ENT-IFIER") }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end
    end
  end
end
