# frozen_string_literal: true

module Sequence
  # Base class for ledger client components.
  # @private
  class ClientModule
    attr_reader :client

    def initialize(client)
      @client = client
    end
  end
end
