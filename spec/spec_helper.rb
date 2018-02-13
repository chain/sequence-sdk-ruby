require 'simplecov'
SimpleCov.start

# When testing backwards compatibility of a legacy SDK release,
# don't load the current `$CHAIN/sdk/ruby/lib`. Avoid conflicts
# such as Ruby constants by removing the directory from the load
# path, relying instead on the published `LEGACY_VERSION` code.
if ENV['LEGACY_VERSION']
  lib_dir = $LOAD_PATH.detect { |path| path.include?('sdk/ruby/lib') }
  $LOAD_PATH.delete(lib_dir)
end

require 'rspec/its'

require 'sequence'
require 'securerandom'
require_relative 'support/utilities'

RSpec.configure do |config|
  config.add_setting :sequence_client

  config.before(:suite) do
    opts = {
      host: 'https://chain.localhost:1999',
      ledger_name: ENV.fetch('LEDGER_NAME', 'test'),
      credential: ENV['MACAROON'],
      refresh_method: lambda { |_|
        {
          'team_name' => ENV.fetch('TEAM_NAME', 'team'),
          'refresh_token' => ENV['DISCHARGE_MACAROON'],
          'refresh_at' => Time.now.to_i + 1000,
        }
      },
      ssl_params: {
        ca_file: ENV['CHAIN'] + '/certs/dev-ca.crt',
      },
    }

    if ENV['LEGACY_VERSION']
      if Gem::Version.new(ENV['LEGACY_VERSION']) < Gem::Version.new('1.1')
        opts[:ledger] = opts[:ledger_name]
        opts[:url] = opts[:host]
      end
    end

    RSpec.configuration.sequence_client = Sequence::Client.new(opts)
  end

  config.include Utilities
end
