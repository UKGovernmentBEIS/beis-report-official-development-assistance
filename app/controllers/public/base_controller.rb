require "sidekiq/api"

class Public::BaseController < ApplicationController
  def health_check
    render json: {
      rails: "OK",
      git_sha: ENV.fetch("CURRENT_SHA", nil),
      built_at: ENV.fetch("TIME_OF_BUILD", nil),
      sidekiq: {
        enqueued: sidekiq_enqueued_size,
        retry_size: sidekiq_retry_size
      }
    }, status: :ok
  end

  private

  def sidekiq_enqueued_size
    Sidekiq::Stats.new.enqueued
  end

  def sidekiq_retry_size
    Sidekiq::Stats.new.retry_size
  end
end
