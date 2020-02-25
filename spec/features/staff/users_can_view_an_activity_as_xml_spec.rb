# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Users can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:user) { create(:beis_user) }
    let(:organisation) { user.organisation }

    context "when the user belongs to BEIS" do
      before { authenticate!(user: user) }

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

      context "when the activity is a project activity" do
        let(:activity) { create(:project_activity_with_implementing_organisations, organisation: organisation) }
        let(:xml) { Nokogiri::XML::Document.parse(page.body) }

        it_behaves_like "valid activity XML"
      end
    end
  end
end
