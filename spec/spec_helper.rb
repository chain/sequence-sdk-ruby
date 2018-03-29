# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'rspec/its'

require 'sequence'
require 'securerandom'
require_relative 'support/utilities'

RSpec.configure do |config|
  config.add_setting :sequence_client

  config.before(:suite) do
    opts = {
      ledger_name: ENV.fetch('LEDGER_NAME', 'test'),
      credential: ENV['SEQCRED'],
    }
    RSpec.configuration.sequence_client = Sequence::Client.new(opts)
  end

  config.include Utilities
end
