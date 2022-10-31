require "rails_helper"

RSpec.describe CommentsHelper, type: :helper do
  let(:comment_clean) { create(:comment, body: "Nice") }
  let(:comment_breaks) { create(:comment, body: "\rThis is a comment. It has some line breaks at both ends\n") }
  let(:comment_spaces) { create(:comment, body: " This is a comment with leading and trailing spaces    ") }
  let(:comments) { [comment_clean, comment_breaks, comment_spaces] }

  describe "#comments_formatted_for_csv" do
    context "when passed multiple comments" do
      it "returns the comment bodies trimmed and joined by a pipe" do
        expect(helper.comments_formatted_for_csv(comments)).to eq(
          "Nice|This is a comment. It has some line breaks at both ends|This is a comment with leading and trailing spaces"
        )
      end
    end

    context "when passed a single comment" do
      context "when the comment body has no leading/trailing spaces or line breaks" do
        it "returns the comment body unchanged" do
          expect(helper.comments_formatted_for_csv([comment_clean])).to eq("Nice")
        end
      end

      context "when the comment has leading/trailing line breaks" do
        it "returns the comment body with leading/trailing line breaks removed" do
          expect(helper.comments_formatted_for_csv([comment_breaks])).to eq("This is a comment. It has some line breaks at both ends")
        end
      end

      context "when the comment has leading/trailing spaces" do
        it "returns the comment body with leading/trailing spaces trimmed" do
          expect(helper.comments_formatted_for_csv([comment_spaces])).to eq("This is a comment with leading and trailing spaces")
        end
      end
    end

    context "when passed no comments" do
      it "returns an empty string" do
        expect(helper.comments_formatted_for_csv([])).to eq("")
      end
    end
  end
end
