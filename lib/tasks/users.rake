desc "Send mass password reset"
namespace :users do
  namespace :active do
    task send_password_resets: :environment do
      User.active.find_each do |user|
        puts user.email
        user_token = user.send(:set_reset_password_token)
        UserMailer.with(params: {}).first_time_devise_reset_password_instructions(user, user_token).deliver!
      rescue Notifications::Client::BadRequestError => e
        warn "Not sending to #{user.email}: #{e}"
      end
    end
  end
end
