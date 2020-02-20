RSpec.configure do |config|
  if Bullet.enable?
    config.before(:each) do
      Bullet.add_whitelist type: :unused_eager_loading, class_name: "User", association: :organisation
      Bullet.add_whitelist type: :unused_eager_loading, class_name: "Activity", association: :organisation
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end
end
