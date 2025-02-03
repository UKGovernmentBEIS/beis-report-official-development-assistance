class AnonymiseDeactivatedUsersJob
  include Sidekiq::Job

  def perform
    User.deactivated.where("deactivated_at < ?", 5.years.ago).each do |user|
      AnonymiseUser.new(user:).call
    end
  end
end
