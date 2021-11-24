require "rails_helper"

RSpec.describe OrgParticipation, type: :model do
  it { should belong_to(:activity) }
  it { should belong_to(:organisation) }
end
