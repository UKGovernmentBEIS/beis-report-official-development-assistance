desc "Lint with ShellCheck"
task shellcheck: :environment do
  files = Dir.glob(["**/*.{sh,ksh,bash}", "script/*[^.rb]"])
    .reject { |path| Dir.exist?(path) }
    .reject { |path| Pathname.new(path).descend.first.to_s == "node_modules" }
    .reject { |path| Pathname.new(path).descend.first.to_s == "vendor" }

  success = system("shellcheck #{files.join(" ")}")

  fail unless success
end
