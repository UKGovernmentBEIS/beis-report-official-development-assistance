# Script to update the 'training/pentest' environment's DB
# from a copy taken from 'prod'.
#
# Run with: `bin/rails runner script/training_db_sync.rb`

class TrainingDbSync
  attr_reader :source, :destination, :data_filename, :pw_reset_script

  ORGANISATION_NAME = "beis-report-official-development-assistance"

  def initialize
    @source = :prod
    @destination = :pentest # this is the old name for 'training'
    @data_filename = "/tmp/#{source}-dump-#{timestamp}.dump"
    @pw_reset_script = "/tmp/pw_reset_script.rb"
  end

  def call
    print_plan
    capture_data_from_source
    copy_data_to_destination
    load_source_data_to_destination
    force_password_reset_for_users
    remove_temp_files
  end

  private

  def authenticate_to(env)
    cmd = "cf login -o #{ORGANISATION_NAME} -s #{env} -u #{cf_user} -p #{cf_password}"
    CmdRunner.run(cmd)
  end

  def timestamp
    DateTime.now.iso8601
  end

  def source_service
    "beis-roda-#{source}-postgres"
  end

  def destination_service
    "beis-roda-#{destination}-postgres"
  end

  def print_plan
    plan =
      "The *#{destination}* db will be dropped and replaced by a copy from *#{source}*. " \
      "Users will need to reset their passwords on their next login to *#{destination}*."
    Kernel.puts plan
  end

  def capture_data_from_source
    authenticate_to(source)

    cmd = <<~CMD
      cf conduit "#{source_service}" -- \
          pg_dump \
              --file "#{data_filename}" \
              --no-acl \
              --clean \
              --no-owner
    CMD
    Kernel.puts "Running pg_dump on #{source} ==> #{cmd}"
    CmdRunner.run(cmd)
  end

  def copy_data_to_destination
    authenticate_to(destination)
    cmd = %(cat #{data_filename} | cf ssh beis-roda-#{destination} -c "cat > #{data_filename}")
    Kernel.puts "Copying data to #{destination} ==> #{cmd}"
    CmdRunner.run(cmd)
  end

  def load_source_data_to_destination
    authenticate_to(destination)
    cmd = <<~CMD
      cf conduit "#{destination_service}" -- \
          psql < #{data_filename}
    CMD
    Kernel.puts "Loading data from #{source} to #{destination} ==> #{cmd}"
    CmdRunner.run(cmd)
  end

  def force_password_reset_for_users
    script = <<~RUBY
      class ResetPasswords
        def call
          User.all.each do |user|
            user.update_columns(
              encrypted_password: '',
              encrypted_otp_secret: nil,
              encrypted_otp_secret_iv: nil,
              encrypted_otp_secret_salt: nil
              )
          end
        end
      end
      ResetPasswords.new.call
    RUBY

    File.write(pw_reset_script, script)

    authenticate_to(destination)
    copy_cmd = %(cat #{pw_reset_script} | cf ssh beis-roda-#{destination} -c "cat > #{pw_reset_script}")
    Kernel.puts "Copying pw reset script to #{destination} ==> #{copy_cmd}"
    CmdRunner.run(copy_cmd)

    reset_cmd = %(cf ssh beis-roda-#{destination} -c "bin/rails runner #{pw_reset_script}")
    Kernel.puts "Running pw reset script on #{destination} ==> #{reset_cmd}"
    CmdRunner.run(reset_cmd)
  end

  def remove_temp_files
    Kernel.puts "Removing temp files..."
    FileUtils.rm([pw_reset_script, data_filename], force: true)
  end

  def cf_user
    ENV.fetch("GPAAS_CF_USER")
  end

  def cf_password
    ENV.fetch("GPAAS_CF_PASSWORD")
  end

  class CmdRunner
    require "open3"

    def self.run(command)
      begin
        stdout, _stderr, _status = Open3.capture3(command)
      rescue => error
        raise "'#{command}' failed (#{error})"
      end

      Kernel.puts stdout.chomp
    end
  end
end

TrainingDbSync.new.call
