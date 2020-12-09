desc "Lint with ShellCheck"
task shellcheck: :environment do
  files = Dir.glob(["**/*.{sh,ksh,bash}", "script/*[^.rb]"]).reject { |path|
    Dir.exist?(path)
  }

  success = system("shellcheck #{files.join(" ")}")

  fail unless success
end
