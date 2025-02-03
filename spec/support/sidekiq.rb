require "sidekiq/testing"
Sidekiq::Testing.fake! # qv. https://github.com/sidekiq/sidekiq/wiki/Testing#testing-worker-queueing-fake
