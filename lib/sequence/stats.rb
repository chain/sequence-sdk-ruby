# frozen_string_literal: true

require_relative './client_module'
require_relative './response_object'
require_relative './query'

module Sequence
  # An object describing summary information about a ledger.
  # @private
  class Stats < ResponseObject
    # @!attribute [r] flavor_count
    # The number of flavors in the ledger.
    # @return [Integer]
    attrib :flavor_count

    # @!attribute [r] account_count
    # The number of accounts in the ledger.
    # @return [Integer]
    attrib :account_count

    # @!attribute [r] tx_count
    # The number of transactions in the ledger.
    # @return [Integer]
    attrib :tx_count

    class ClientModule < Sequence::ClientModule
      # Gets stats from the ledger.
      # @return [Stats]
      def get
        Stats.new(client.session.request('stats'))
      end
    end
  end
end
