# frozen_string_literal: true

require_relative './validations'

module Sequence
  # Base class for ledger client components.
  # @private
  class ClientModule
    include Sequence::Validations

    attr_reader :client

    def initialize(client)
      @client = client
    end
  end
end
