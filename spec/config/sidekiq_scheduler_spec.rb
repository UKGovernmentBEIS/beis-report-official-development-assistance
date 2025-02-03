require "rails_helper"
require "fugit"

RSpec.describe "sidekiq-scheduler" do
  sidekiq_file = File.join(Rails.root, "config", "sidekiq.yml")
  schedule = YAML.load_file(sidekiq_file)[:scheduler][:schedule]

  describe "cron syntax" do
    schedule.each do |job_name, values|
      cron = values["cron"]
      it "#{job_name} has correct cron syntax" do
        expect { Fugit.do_parse(cron) }.not_to raise_error
      end
    end
  end

  describe "job classes" do
    schedule.each do |job_name, values|
      klass = values["class"]
      it "#{job_name} has #{klass} class in /jobs" do
        expect { klass.constantize }.not_to raise_error
      end
    end
  end

  describe "job names" do
    schedule.each do |job_name, values|
      klass = values["class"]
      it "#{job_name} has correct name" do
        expect(klass.underscore).to start_with(job_name)
      end
    end
  end
end
