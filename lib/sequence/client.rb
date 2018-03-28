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
    include Sequence::Validations

    # @param [Hash] opts
    #   Options hash
    # @option opts [String] ledger_name
    #   Ledger name.
    # @option opts [String] credential
    #   API credential secret.
    # @return [Query]
    def initialize(opts = {})
      validate_required!(opts, :ledger_name)
      validate_required!(opts, :credential)

      addr = ENV['SEQADDR'] || 'api.seq.com'
      api = HttpWrapper.new('https://' + addr, opts[:credential], opts)
      @opts = opts.merge(team_name: team_name(api), addr: addr)
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

    # @return [Flavor::ClientModule]
    def flavors
      @flavors ||= Flavor::ClientModule.new(self)
    end

    # @return [Action::ClientModule]
    def actions
      @actions ||= Action::ClientModule.new(self)
    end

    # @return [Key::ClientModule]
    def keys
      @keys ||= Key::ClientModule.new(self)
    end

    # @return [Token::ClientModule]
    def tokens
      @tokens ||= Token::ClientModule.new(self)
    end

    # @return [Transaction::ClientModule]
    def transactions
      @transactions ||= Transaction::ClientModule.new(self)
    end

    # @return [Feed::ClientModule]
    def feeds
      @feeds ||= Feed::ClientModule.new(self)
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

    private

    def team_name(api)
      api.post(SecureRandom.hex(10), '/hello', {})[:parsed_body]['team_name']
    end
  end
end
