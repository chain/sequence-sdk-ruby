# frozen_string_literal: true

require 'securerandom'

require_relative './client_module'

module Sequence
  class DevUtils
    # A namespace for development-only methods.
    class ClientModule < Sequence::ClientModule
      # Deletes all data in the ledger.
      def reset
        client.session.request('/reset')
      end
    end
  end
end
