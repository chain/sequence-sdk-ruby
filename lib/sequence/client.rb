# frozen_string_literal: true

require_relative './account'
require_relative './action'
require_relative './dev_utils'
require_relative './feed'
require_relative './flavor'
require_relative './http_wrapper'
require_relative './key'
require_relative './stats'
require_relative './token'
require_relative './transaction'

module Sequence
  class Client
    # Set up a Sequence client.
    # This is the entry point for all other Sequence interaction.
    # @param ledger_name [String]
    #   Ledger name.
    # @param credential [String]
    #   API credential secret.
    # @return [Query]
    def initialize(ledger_name:, credential:)
      if ledger_name.nil? || ledger_name == ''
        raise ArgumentError, ':ledger_name cannot be blank'
      end
      if credential.nil? || credential == ''
        raise ArgumentError, ':credential cannot be blank'
      end

      @opts = {
        credential: credential,
        ledger_name: ledger_name,
      }
      @session = Session.new(@opts)
    end

    # @private
    def opts
      @opts.dup
    end

    # @private
    # @return [Session]
    attr_reader :session

    # @return [Account::ClientModule]
    def accounts
      @accounts ||= Account::ClientModule.new(self)
    end

    # @return [Action::ClientModule]
    def actions
      @actions ||= Action::ClientModule.new(self)
    end

    # @return [Feed::ClientModule]
    def feeds
      @feeds ||= Feed::ClientModule.new(self)
    end

    # @return [Flavor::ClientModule]
    def flavors
      @flavors ||= Flavor::ClientModule.new(self)
    end

    # @return [Key::ClientModule]
    def keys
      @keys ||= Key::ClientModule.new(self)
    end

    # @private
    # @return [Stats::ClientModule]
    def stats
      @stats ||= Stats::ClientModule.new(self)
    end

    # @return [Token::ClientModule]
    def tokens
      @tokens ||= Token::ClientModule.new(self)
    end

    # @return [Transaction::ClientModule]
    def transactions
      @transactions ||= Transaction::ClientModule.new(self)
    end

    # @return [DevUtils::ClientModule]
    def dev_utils
      @dev_utils ||= DevUtils::ClientModule.new(self)
    end
  end
end
