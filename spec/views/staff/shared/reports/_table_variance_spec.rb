RSpec.describe "staff/shared/reports/_table_variance" do
  before do
    assign(:report, create(:report))
    activity = build_stubbed(:project_activity)
    policy = double("policy")
    allow(policy).to receive(:create?).and_return(create_comment)
    allow(view).to receive(:organisation_activity_comments_path)
      .and_return("This is not the path you are looking for")

    without_partial_double_verification do
      allow(view).to receive(:policy).with([:activity, :comment]).and_return(policy)
    end

    render partial: "staff/shared/reports/table_variance", locals: {
      activities: [activity],
      readonly: false
    }
  end

  context "when the user can add a comment" do
    let(:create_comment) { true }

    it "shows a link to view and add to an activity's comments" do
      expect(rendered).to have_content(t("table.body.report.view_and_add_comments"))
    end
  end

  context "when the user cannot add a comment" do
    let(:create_comment) { false }

    it "shows a link to view an activity's comments" do
      expect(rendered).to have_content(t("table.body.report.view_comments"))
    end
  end
end
