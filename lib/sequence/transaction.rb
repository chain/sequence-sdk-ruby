# frozen_string_literal: true

require 'securerandom'

require_relative './client_module'
require_relative './query'
require_relative './response_object'

module Sequence
  # A transaction is an atomic update to the state of the ledger. Transactions
  # can issue new flavor units, transfer of flavor units from one account to
  # another, and/or the retire flavor units from an account.
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

    # @!attribute [r] actions
    #   List of actions taken by the transaction.
    # @return [Array<Action>]
    attrib(:actions) { |raw| raw.map { |v| Action.new(v) } }

    # @!attribute [r] tags
    #   User-specified key-value data embedded in the transaction.
    # @return [Hash]
    attrib :tags

    class ClientModule < Sequence::ClientModule
      # Build, sign, and submit a transaction.
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

        Transaction.new(
          client.session.request('transact', builder),
        )
      end

      # Execute a query, returning an enumerable over individual transactions.
      # @param filter [String]
      #   A filter expression.
      # @param filter_params [Array<String|Integer>]
      #   A list of values that will be interpolated into the filter expression.
      # @return [Query]
      def list(filter: nil, filter_params: nil)
        Query.new(client, filter: filter, filter_params: filter_params)
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

    # A configuration object for creating and submitting transactions.
    class Builder
      def initialize(&block)
        yield(self) if block
      end

      # @private
      def actions
        @actions ||= []
      end

      # @private
      def transaction_tags
        @transaction_tags || {}
      end

      # @private
      def to_h
        { actions: actions, transaction_tags: transaction_tags }
      end

      # @private
      def to_json(opts = nil)
        to_h.to_json(opts)
      end

      # @private
      def add_action(opts = {})
        if opts[:amount].nil?
          raise ArgumentError, ':amount must be provided'
        end
        actions << opts
        self
      end

      # Add tags to the transaction
      # @param [Hash] tags
      #   Transaction tags
      # @return [Builder]
      def transaction_tags=(tags)
        @transaction_tags = tags
        self
      end

      # Issue new tokens to a destination account.
      # @param amount [Integer]
      #   Amount of the flavor to be issued.
      # @param flavor_id [String]
      #   ID of the flavor to be issued.
      # @param destination_account_id [String]
      #   ID of the account receiving the flavor units.
      # @param token_tags [Hash]
      #   Tags to add to the receiving tokens.
      # @param action_tags [Hash]
      #   Tags to add to the action.
      # @return [Builder]
      def issue(
        amount:,
        flavor_id:,
        destination_account_id:,
        token_tags: {},
        action_tags: {}
      )
        add_action(
          type: :issue,
          amount: amount,
          flavor_id: flavor_id,
          destination_account_id: destination_account_id,
          token_tags: token_tags,
          action_tags: action_tags,
        )
      end

      # Move tokens from a source account to a destination account.
      # @param amount [Integer]
      #   Amount of the flavor to be transferred.
      # @param flavor_id [String]
      #   ID of the flavor to be transferred.
      # @param source_account_id [String]
      #   ID of the account serving as the source of flavor units.
      # @param destination_account_id [String]
      #   ID of the account receiving the flavor units.
      # @param filter [String]
      #   Token filter string. See {https://dashboard.seq.com/docs/filters}.
      # @param filter_params [Array<String|Integer>]
      #   A list of parameter values for filter string (if needed).
      # @param token_tags [Hash]
      #   Tags to add to the receiving tokens.
      # @param action_tags [Hash]
      #   Tags to add to the action.
      # @return [Builder]
      def transfer(
        amount:,
        flavor_id:,
        source_account_id:,
        destination_account_id:,
        filter: nil,
        filter_params: nil,
        token_tags: {},
        action_tags: {}
      )
        add_action(
          type: :transfer,
          amount: amount,
          flavor_id: flavor_id,
          source_account_id: source_account_id,
          destination_account_id: destination_account_id,
          filter: filter,
          filter_params: filter_params,
          token_tags: token_tags,
          action_tags: action_tags,
        )
      end

      # Take tokens from a source account and retire them.
      # @param amount [Integer]
      #   Amount of the flavor to be retired.
      # @param flavor_id [String]
      #   ID of the flavor to be retired.
      # @param source_account_id [String]
      #   ID of the account serving as the source of flavor units.
      # @param filter [String]
      #   Token filter string. See {https://dashboard.seq.com/docs/filters}.
      # @param filter_params [Array<String|Integer>]
      #   A list of parameter values for filter string (if needed).
      # @param action_tags [Hash]
      #   Tags to add to the action.
      # @return [Builder]
      def retire(
        amount:,
        flavor_id:,
        source_account_id:,
        filter: nil,
        filter_params: nil,
        action_tags: {}
      )
        add_action(
          type: :retire,
          amount: amount,
          flavor_id: flavor_id,
          source_account_id: source_account_id,
          filter: filter,
          filter_params: filter_params,
          action_tags: action_tags,
        )
      end
    end
  end
end
