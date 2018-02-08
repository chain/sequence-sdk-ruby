require_relative './account'
require_relative './action'
require_relative './asset'
require_relative './balance'
require_relative './contract'
require_relative './dev_utils'
require_relative './feed'
require_relative './key'
require_relative './stats'
require_relative './transaction'

module Sequence
  class Client
    # @param [Hash] opts
    #   Options hash
    # @option opts [String] ledger_name
    #   Ledger name.
    # @option opts [String] ledger
    #   Deprecated. Use :ledger_name instead.
    #   Ledger name.
    # @option opts [String] credential
    #   API credential secret.
    # @return [Query]
    def initialize(opts = {})
      if (opts[:ledger_name].nil? || opts[:ledger_name].empty?) == (opts[:ledger].nil? || opts[:ledger].empty?)
        raise ArgumentError, ':ledger_name or :ledger (but not both) must be provided'
      end
      if opts[:credential].nil? || opts[:credential].empty?
        raise ArgumentError, ':credential must be provided'
      end

      if opts[:ledger_name].nil? || opts[:ledger_name].empty?
        opts[:ledger_name] = opts[:ledger]
      end
      @opts = opts
    end

    # @private
    def opts
      @opts.dup
    end

    # @private
    # @return [Session]
    def session
      @session ||= Session.new(@opts)
    end

    # @return [Account::ClientModule]
    def accounts
      @accounts ||= Account::ClientModule.new(self)
    end

    # @return [Asset::ClientModule]
    def assets
      @assets ||= Asset::ClientModule.new(self)
    end

    # @return [Action::ClientModule]
    def actions
      @actions ||= Action::ClientModule.new(self)
    end

    # @return [Balance::ClientModule]
    def balances
      @balances ||= Balance::ClientModule.new(self)
    end

    # @return [Key::ClientModule]
    def keys
      @keys ||= Key::ClientModule.new(self)
    end

    # @return [Transaction::ClientModule]
    def transactions
      @transactions ||= Transaction::ClientModule.new(self)
    end

    # @return [Feed::ClientModule]
    def feeds
      @feeds ||= Feed::ClientModule.new(self)
    end

    # @return [Contract::ClientModule]
    def contracts
      @contracts ||= Contract::ClientModule.new(self)
    end

    # @private
    # @return [Stats::ClientModule]
    def stats
      @stats ||= Stats::ClientModule.new(self)
    end

    # @return [DevUtils::ClientModule]
    def dev_utils
      @dev_utils ||= DevUtils::ClientModule.new(self)
    end
  end
end
