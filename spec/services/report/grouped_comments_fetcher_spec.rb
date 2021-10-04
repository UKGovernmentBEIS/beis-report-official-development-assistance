RSpec.describe Report::GroupedCommentsFetcher do
  let(:report) { build(:report) }
  let(:comment_relation) { double("ActiveRecord::Relation") }

  let(:activities) do
    [
      build(:project_activity, id: SecureRandom.uuid),
      build(:project_activity, id: SecureRandom.uuid),
      build(:project_activity, id: SecureRandom.uuid),
    ]
  end

  let(:comments) do
    [
      build_list(:comment, 3, activity: activities[0]),
      build_list(:comment, 2, activity: activities[1]),
    ]
  end

  let(:grouped_comments) do
    {
      activities[0] => comments[0],
      activities[1] => comments[1],
    }
  end

  subject { described_class.new(report: report, user: user) }

  before do
    allow(report).to receive(:comments).and_return(comment_relation)
  end

  context "when the user is a delivery partner" do
    let(:user) { build(:delivery_partner_user) }

    it "returns comments, grouped by activity" do
      expect(comment_relation).to receive(:includes).with(
        owner: [:organisation],
        activity: [
          parent: [
            parent: [:parent],
          ],
        ]
      ).and_return(comments.flatten)

      expect(subject.all).to eq(grouped_comments)
    end
  end

  context "when the user is a service owner" do
    let(:user) { build(:beis_user) }

    it "returns comments, grouped by activity" do
      expect(comment_relation).to receive(:includes).with(:activity).and_return(comments.flatten)

      expect(subject.all).to eq(grouped_comments)
    end
  end
end
