FactoryBot.define do
  factory :flexible_comment do
    commentable { association(:refund) }
    comment { "A narrative explaining some scenario" }
  end
end
