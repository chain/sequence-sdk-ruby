# frozen_string_literal: true

module Sequence
  # @private
  class Hello
    def initialize(api, ledger_name)
      @api = api
      @ledger_name = ledger_name
    end

    def call
      b = @api.post(SecureRandom.hex(10), '/hello', {ledger_name: @ledger_name})[:parsed_body]
      [b['team_name'], b['addr'], b['addr_ttl_seconds'].to_i]
    end
  end
end
