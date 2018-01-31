require 'simplecov'
SimpleCov.start

require 'rspec/its'

require 'sequence'
require 'securerandom'
require_relative 'support/utilities'

RSpec.configure do |config|
  config.add_setting :sequence_client

  config.before(:suite) do
    RSpec.configuration.sequence_client = Sequence::Client.new(
      host: "https://chain.localhost:1999",
      ledger_name: ENV.fetch('LEDGER_NAME', 'test'),
      credential: ENV['MACAROON'],
      refresh_method: lambda { |_|
        {
          'team_name' => ENV.fetch('TEAM_NAME', 'team'),
          'refresh_token' => ENV['DISCHARGE_MACAROON'],
          'refresh_at' => Time.now.to_i + 1000
        }
      },
      ssl_params: {
        ca_file: ENV['CHAIN'] + '/certs/dev-ca.crt',
      },
    )
  end

  config.include Utilities
end
