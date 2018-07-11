# frozen_string_literal: true

module Sequence
  # @private
  class Hello
    def initialize(api)
      @api = api
    end

    def call
      b = @api.post(SecureRandom.hex(10), '/hello', {})[:parsed_body]
      [b['team_name'], b['addr'], b['addr_ttl_seconds'].to_i]
    end
  end
end
