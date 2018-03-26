# frozen_string_literal: true

require 'securerandom'

require_relative './client_module'
require_relative './query'
require_relative './response_object'
require_relative './validations'

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

        Transaction.new(
          client.session.request('transact', builder),
        )
      end

      # Executes a query, returning an enumerable over individual transactions.
      # @param [Hash] opts Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @return [Query]
      def list(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
        )
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

    # A configuration object for creating and submitting transactions.
    class Builder
      include Sequence::Validations

      def initialize(&block)
        yield(self) if block
      end

      def actions
        @actions ||= []
      end

      def to_h
        { actions: actions }
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

      # Issues new tokens to a destination account.
      #
      # @param [Hash] opts
      #   Options hash
      # @option opts [Integer] :amount
      #   Amount of the flavor to be issued.
      # @option opts [String] :flavor_id
      #   ID of the flavor to be issued.
      # @option opts [String] :destination_account_id
      #   ID of the account receiving the flavor units.
      # @option opts [Hash] :token_tags
      #   Tags to add to the receiving tokens.
      # @option opts [Hash] :action_tags
      #   Tags to add to the action.
      # @return [Builder]
      def issue(opts = {})
        validate_inclusion_of!(
          opts,
          :amount,
          :flavor_id,
          :destination_account_id,
          :token_tags,
          :action_tags,
        )
        validate_required!(opts, :amount)
        validate_required!(opts, :destination_account_id)
        validate_required!(opts, :flavor_id)
        add_action(opts.merge(type: :issue))
      end

      # Moves tokens from a source account to a
      # destination account.
      #
      # @param [Hash] opts
      #   Options hash
      # @option opts [Integer] :amount
      #   Amount of the flavor to be transferred.
      # @option opts [String] :flavor_id
      #   ID of the flavor to be transferred.
      # @option opts [String] filter
      #   Token filter string. See {https://dashboard.seq.com/docs/filters}.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of parameter values for filter string (if needed).
      # @option opts [String] :source_account_id
      #   ID of the account serving as the source of flavor units.
      # @option opts [String] :destination_account_id
      #   ID of the account receiving the flavor units.
      # @option opts [Hash] :token_tags
      #   Tags to add to the receiving tokens.
      # @option opts [Hash] :action_tags
      #   Tags to add to the action.
      # @return [Builder]
      def transfer(opts = {})
        validate_inclusion_of!(
          opts,
          :amount,
          :flavor_id,
          :filter,
          :filter_params,
          :source_account_id,
          :destination_account_id,
          :token_tags,
          :action_tags,
        )
        validate_required!(opts, :amount)
        validate_required!(opts, :destination_account_id)
        validate_required!(opts, :flavor_id)
        validate_required!(opts, :source_account_id)
        add_action(opts.merge(type: :transfer))
      end

      # Takes tokens from a source account and
      # retires them.
      #
      # @param [Hash] opts Options hash
      # @option opts [Integer] :amount
      #   Amount of the flavor to be retired.
      # @option opts [String] :flavor_id
      #   ID of the flavor to be retired.
      # @option opts [String] filter
      #   Token filter string. See {https://dashboard.seq.com/docs/filters}.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of parameter values for filter string (if needed).
      # @option opts [String] :source_account_id
      #   ID of the account serving as the source of flavor units.
      # @option opts [Hash] :action_tags
      #   Tags to add to the action.
      # @return [Builder]
      def retire(opts = {})
        validate_inclusion_of!(
          opts,
          :amount,
          :flavor_id,
          :filter,
          :filter_params,
          :source_account_id,
          :action_tags,
        )
        validate_required!(opts, :amount)
        validate_required!(opts, :flavor_id)
        validate_required!(opts, :source_account_id)
        add_action(opts.merge(type: :retire))
      end
    end
  end
end
