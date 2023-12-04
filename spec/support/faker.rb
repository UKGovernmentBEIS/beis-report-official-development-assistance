RSpec.configure do |config|
  config.before(:each) do
    Faker::Alphanumeric.unique.clear
  end
end
