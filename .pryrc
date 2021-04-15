# Define prompt colours
ANSI_FG_RED = "\u001b[31m"
ANSI_FG_YELLOW = "\u001b[33m"
ANSI_RESET = "\u001b[0m"

if defined?(Rails)
  hostname = ENV.fetch("CANONICAL_HOSTNAME", "").split(".").first

  case hostname
  when "www"
    environment_colour = ANSI_FG_RED
    environment_name = "production"
  when "staging", "sandbox", "training", "pentest"
    environment_colour = ANSI_FG_YELLOW
    environment_name = hostname
  else
    environment_colour = ""
    environment_name = Rails.env
  end

  sandbox_status = "(writable)"
  sandbox_status = "(sandbox)" if Rails.application.sandbox

  if Rails.application.sandbox == false && environment_name == "production"
    puts
    puts ANSI_FG_RED + "*******************************************************************" + ANSI_RESET
    puts ANSI_FG_RED + "Warning: You are using the production console in non-sandboxed mode" + ANSI_RESET
    puts ANSI_FG_RED + "*******************************************************************" + ANSI_RESET
  end

  puts

  Pry.config.prompt_name = [
    environment_colour,
    environment_name,
    " ",
    ANSI_RESET,
    sandbox_status,
    " ",
  ].join
end
