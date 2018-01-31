require 'securerandom'

require_relative './client_module'
require_relative './query'
require_relative './response_object'
require_relative './validations'

module Sequence
  # A transaction is an atomic update to the state of the ledger. Transactions
  # can issue new asset units, transfer of asset units from one account to
  # another, and/or the retire asset units from an account.
  class Transaction < ResponseObject
    # @!attribute [r] id
    #   A unique ID.
    # @return [String]
    attrib :id

    # @!attribute [r] timestamp
    #   Time of transaction.
    # @return [Time]
    attrib :timestamp, rfc3339_time: true

    # @!attribute [r] sequence_number
    #   Sequence number of the transaction.
    # @return [Integer]
    attrib :sequence_number

    # @!attribute [r] reference_data
    #   User-specified key-value data embedded into the transaction.
    # @return [Hash]
    attrib :reference_data

    # @!attribute [r] actions
    #   List of actions taken by the transaction.
    # @return [Array<Action>]
    attrib(:actions) { |raw| raw.map { |v| Action.new(v) } }

    # @!attribute [r] contracts
    #   List of contracts created by the transaction.
    # @return [Array<Contract>]
    attrib(:contracts) { |raw| raw.map { |v| Contract.new(v) } }

    class ClientModule < Sequence::ClientModule
      # Builds, signs, and submits a transaction.
      # @param [Builder] builder
      #   Builder object with actions defined. If provided, overrides block
      #   parameter.
      # @yield Block defining transaction actions. A {Builder} object is passed
      #   as the only parameter.
      # @return Transaction
      def transact(builder = nil, &block)
        if builder.nil?
          builder = Builder.new(&block)
        end

        tpl = client.session.request('build-transaction', builder)
        tpl = client.session.request(
          '/sign-transaction',
          transaction: tpl,
        )
        Transaction.new(
          client.session.request('submit-transaction', transaction: tpl),
        )
      end

      # Executes a query, returning an enumerable over individual transactions.
      # @param [Hash] opts Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Integer] start_time
      #   A Unix timestamp in milliseconds of the earliest transaction timestamp
      #   to include in the query results.
      # @option opts [Integer] end_time
      #   A Unix timestamp in milliseconds of the most recent transaction
      #   timestamp to include in the query results.
      # @option opts [Integer>] page_size
      #   The number of items to return in the result set.
      # @return [Query]
      def query(opts = {})
        Query.new(client, opts)
      end
    end

    class Query < Sequence::Query
      def fetch(query)
        client.session.request('list-transactions', query)
      end

      def translate(raw)
        Transaction.new(raw)
      end
    end

    # An action taken by a transaction.
    class Action < ResponseObject
      # @!attribute [r] type
      #   The type of the action. Possible values are "issue", "transfer" and
      #   "retire".
      # @return [String]
      attrib :type

      # @!attribute [r] asset_id
      #   The id of the action's asset.
      # @return [String]
      attrib :asset_id

      # @!attribute [r] asset_alias
      #   The alias of the action's asset.
      # @return [String]
      attrib :asset_alias

      # @!attribute [r] asset_tags
      #   The tags of the action's asset.
      # @return [Hash]
      attrib :asset_tags

      # @!attribute [r] amount
      #   The number of asset units issues, transferred, or retired.
      # @return [Integer]
      attrib :amount

      # @!attribute [r] source_account_id
      #   The ID of the account serving as the source of asset units. Null for
      #   issuances.
      # @return [String]
      attrib :source_account_id

      # @!attribute [r] source_account_alias
      #   The alias of the account serving as the source of asset units. Null
      #   for issuances.
      # @return [String]
      attrib :source_account_alias

      # @!attribute [r] source_account_tags
      #   The tags of the account serving as the source of asset units. Null for
      #   issuances.
      # @return [String]
      attrib :source_account_tags

      # @!attribute [r] destination_account_id
      #   The ID of the account receiving the asset units. Null for retirements.
      # @return [String]
      attrib :destination_account_id

      # @!attribute [r] destination_account_alias
      #   The alias of the account receiving the asset units. Null for
      #   retirements.
      # @return [String]
      attrib :destination_account_alias

      # @!attribute [r] destination_account_tags
      #   The tags of the account receiving the asset units. Null for
      #   retirements.
      # @return [String]
      attrib :destination_account_tags

      # @!attribute [r] reference_data
      #   User-specified, key-value data embedded into the action.
      # @return [Hash]
      attrib :reference_data
    end

    # A configuration object for creating and submitting transactions.
    class Builder
      include Sequence::Validations

      attr_accessor :reference_data

      def initialize(&block)
        yield(self) if block
      end

      def actions
        @actions ||= []
      end

      def to_h
        {
          actions: actions,
          reference_data: reference_data,
        }
      end

      def to_json(opts = nil)
        to_h.to_json(opts)
      end

      # Adds an action to a transaction builder.
      # @param [Hash] opts
      #   Action parameters.
      # @return [Builder]
      def add_action(opts = {})
        if opts[:amount].nil?
          raise ArgumentError, ':amount must be provided'
        end
        actions << opts
        self
      end

      # Issues new units of an asset to a destination account.
      #
      # @param [Hash] opts
      #   Options hash
      # @option opts [Integer] :amount
      #   Amount of the asset to be issued.
      # @option opts [String] :asset_id
      #   ID of the asset to be issued. You must specify either an ID or an
      #   alias.
      # @option opts [String] :asset_alias
      #   Asset alias of the asset to be issued. You must specify either an ID
      #   or an alias.
      # @option opts [String] :destination_account_id
      #   ID of the account receiving the asset units. You must specify a
      #   destination account ID or alias.
      # @option opts [String] :destination_account_alias
      #   Alias of the account receiving the asset units. You must specify a
      #   destination account ID or alias.
      # @option opts [Hash] :reference_data
      #   Reference data for the action.
      # @return [Builder]
      def issue(opts = {})
        validate_inclusion_of!(
          opts,
          :amount,
          :asset_id,
          :asset_alias,
          :destination_account_id,
          :destination_account_alias,
          :reference_data,
        )
        validate_either!(opts, :asset_id, :asset_alias)
        validate_either!(
          opts,
          :destination_account_id,
          :destination_account_alias,
        )
        add_action(opts.merge(type: :issue))
      end

      # Moves units of an asset from a source (an account or contract) to a
      # destination account.
      #
      # @param [Hash] opts
      #   Options hash
      # @option opts [Integer] :amount
      #   Amount of the asset to be transferred.
      # @option opts [String] :asset_id
      #   ID of the asset to be transferred. You must specify either an ID or an
      #   alias.
      # @option opts [String] :asset_alias
      #   Asset alias of the asset to be transferred. You must specify either an
      #   ID or an alias.
      # @option opts [String] :source_account_id
      #   ID of the account serving as the source of asset units. You must
      #   specify a source account ID, account alias, or contract ID.
      # @option opts [String] :source_account_alias
      #   Alias of the account serving as the source of asset units You must
      #   specify a source account ID, account alias, or contract ID.
      # @option opts [String] :source_contract_id
      #   ID of the contract serving as the source of asset units. You must
      #   specify a source account ID, account alias, or contract ID.
      # @option opts [String] :destination_account_id
      #   ID of the account receiving the asset units. You must specify a
      #   destination account ID or alias.
      # @option opts [String] :destination_account_alias
      #   Alias of the account receiving the asset units. You must specify a
      #   destination account ID or alias.
      # @option opts [Hash] :reference_data
      #   reference data for the action.
      # @option opts [Hash] :change_reference_data
      #   reference data for the change contract.
      # @return [Builder]
      def transfer(opts = {})
        validate_inclusion_of!(
          opts,
          :amount,
          :asset_id,
          :asset_alias,
          :source_account_id,
          :source_account_alias,
          :source_contract_id,
          :destination_account_id,
          :destination_account_alias,
          :reference_data,
          :change_reference_data,
        )
        validate_either!(opts, :asset_id, :asset_alias)
        validate_either!(
          opts,
          :source_account_id,
          :source_account_alias,
          :source_contract_id,
        )
        validate_either!(
          opts,
          :destination_account_id,
          :destination_account_alias,
        )
        add_action(opts.merge(type: :transfer))
      end

      # Takes units of an asset from a source (an account or contract) and
      # retires them.
      #
      # @param [Hash] opts Options hash
      # @option opts [Integer] :amount
      #   Amount of the asset to be retired.
      # @option opts [String] :asset_id
      #   ID of the asset to be retired. You must specify either an ID or an
      #   alias.
      # @option opts [String] :asset_alias
      #   Asset alias of the asset to be retired. You must specify either an ID
      #   or an alias.
      # @option opts [String] :source_account_id
      #   ID of the account serving as the source of asset units. You must
      #   specify a source account ID, account alias, or contract ID.
      # @option opts [String] :source_account_alias
      #   Alias of the account serving as the source of asset units You must
      #   specify a source account ID, account alias, or contract ID.
      # @option opts [String] :source_contract_id
      #   ID of the contract serving as the source of asset units. You must
      #   specify a source account ID, account alias, or contract ID.
      # @option opts [Hash] :reference_data
      #   Reference data for the action.
      # @option opts [Hash] :change_reference_data
      #   Reference data for the change contract.
      # @return [Builder]
      def retire(opts = {})
        validate_inclusion_of!(
          opts,
          :amount,
          :asset_id,
          :asset_alias,
          :source_account_id,
          :source_account_alias,
          :source_contract_id,
          :reference_data,
          :change_reference_data,
        )
        validate_either!(opts, :asset_id, :asset_alias)
        validate_either!(
          opts,
          :source_account_id,
          :source_account_alias,
          :source_contract_id,
        )
        add_action(opts.merge(type: :retire))
      end
    end
  end
end
