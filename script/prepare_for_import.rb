require "optparse"
require_relative "../config/environment"

parser = OptionParser.new { |args|
  args.on "-f", "--fund FUND"
  args.on "-o", "--organisation ORGANISATION"
  args.on "-u", "--user EMAIL"
}

options = {}
parser.parse!(into: options)

user_email = options.fetch(:user, "roda+dp@dxw.com")

fund = Activity.fund.by_roda_identifier(options.fetch(:fund))
organisation = Organisation.find_by(name: options.fetch(:organisation))
user = User.find_by(email: user_email)

unless fund
  warn "Could not find fund with RODA identifier '#{options.fetch(:fund)}'"
  exit 1
end

unless organisation
  warn "Could not find organisation with name '#{options.fetch(:organisation)}'"
  exit 1
end

unless user
  warn "Could not find organisation with email '#{user_email}'"
  exit 1
end

user.organisation = organisation
user.save

Report.create(fund: fund, organisation: organisation, state: "active")
