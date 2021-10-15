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
      build_list(:comment, 3, commentable: activities[0]),
      build_list(:comment, 2, commentable: activities[1]),
      build(:comment, commentable: build(:refund, parent_activity: activities[0]), commentable_type: "Refund"),
      build(:comment, commentable: build(:adjustment, parent_activity: activities[1]), commentable_type: "Adjustment"),
    ]
  end

  let(:first_activity_comments) { comments[0].append(comments[2]) }
  let(:second_activity_comments) { comments[1].append(comments[3]) }

  let(:grouped_comments) do
    {
      activities[0] => first_activity_comments,
      activities[1] => second_activity_comments,
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
        commentable: [
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
      expect(comment_relation).to receive(:includes).with(:commentable).and_return(comments.flatten)

      expect(subject.all).to eq(grouped_comments)
    end
  end
end
