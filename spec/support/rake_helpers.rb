require "rake"

module TaskExampleGroup
  extend ActiveSupport::Concern

  included do
    def silent_warnings
      old_stderr = $stderr
      $stderr = StringIO.new
      yield
    ensure
      $stderr = old_stderr
    end

    let(:task_name) { self.class.top_level_description.sub(/\Arake /, "") }
    let(:tasks) { Rake::Task }

    # Make the Rake task available as `task` in your examples:
    subject(:task) { tasks[task_name] }

    # Silence any errors that get sent to stderr when the task gets run
    around(:example) do |example|
      silent_warnings { example.run }
    end
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/lib/tasks/}) do |metadata|
    metadata[:type] = :task
  end

  config.include TaskExampleGroup, type: :task

  config.before(:suite) do
    Rails.application.load_tasks
  end
end
