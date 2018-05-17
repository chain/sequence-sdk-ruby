# frozen_string_literal: true

require_relative './client_module'
require_relative './response_object'
require_relative './query'

module Sequence
  # Each transaction contains one or more actions. Action queries are designed
  # to provide insights into those actions. There are two types of queries you
  # can run against them; one is "list", one is "sum". List query simply returns
  # a list of Action objects that match the filter; Sum query sums over the
  # amount fields based on the filter and the group_by param and return
  # ActionSum objects. Different from other regular API objects, the amount
  # field in ActionSum represents the summation of the amount fields of those
  # matching actions, and all other fields represent the parameters by which to
  # group actions.
  class Action < ResponseObject
    # @!attribute [r] amount
    #   Summation of action amounts.
    # @return [Integer]
    attrib :amount

    # @!attribute [r] type
    #   The type of the action. Currently, there are three options: "issue",
    #   "transfer", "retire".
    # @return [String]
    attrib :type

    # @!attribute [r] id
    #   A unique ID.
    # @return [String]
    attrib :id

    # @!attribute [r] transaction_id
    #   The ID of the transaction in which the action appears.
    # @return [String]
    attrib :transaction_id

    # @!attribute [r] timestamp
    #   Time of the action.
    # @return [Time]
    attrib :timestamp, rfc3339_time: true

    # @!attribute [r] flavor_id
    #   The ID of the flavor held by the action.
    # @return [String]
    attrib :flavor_id

    # @!attribute [r] snapshot
    #   A copy of the associated tags (flavor, source account, destination
    #   account, action, and token) as they existed at the time of the
    #   transaction.
    # @return [Hash]
    attrib :snapshot, snapshot: true

    # @!attribute [r] source_account_id
    #   The ID of the source account executing the action.
    # @return [String]
    attrib :source_account_id

    # @!attribute [r] destination_account_id
    #   The ID of the destination account affected by the action.
    # @return [String]
    attrib :destination_account_id

    # @!attribute [r] tags
    #   User-specified key-value data embedded in the action.
    # @return [Hash]
    attrib :tags

    class ClientModule < Sequence::ClientModule
      # Execute a query, returning an enumerable over individual actions.
      # @param filter [String]
      #   A filter expression.
      # @param filter_params [Array<String|Integer>]
      #   A list of values that will be interpolated into the filter expression.
      # @return [Query]
      # @example List all actions after a certain time
      #    ledger.actions.list(
      #      filter: 'timestamp > $1',
      #      filter_params: ['1985-10-26T01:21:00Z']
      #    ).each do |action|
      #      puts 'timestamp: ' + action.timestamp
      #      puts 'amount: ' + action.amount
      #    end
      def list(filter: nil, filter_params: nil)
        ListQuery.new(client, filter: filter, filter_params: filter_params)
      end

      # Update an action's tags.
      # @param id [String]
      #    The ID of the action.
      # @param tags [Hash]
      #    A new set of tags, which will replace the existing tags.
      # @return [void]
      def update_tags(id:, tags: nil)
        raise ArgumentError, ':id cannot be blank' if id == ''
        client.session.request('update-action-tags', id: id, tags: tags)
      end

      # Execute a query, returning an enumerable over sums of actions.
      # @param filter [String]
      #   A filter expression.
      # @param filter_params [Array<String|Integer>]
      #   A list of values that will be interpolated into the filter expression.
      # @param group_by [Array<String>]
      #   A list of fields along which action values will be summed.
      # @return [Query]
      def sum(filter: nil, filter_params: nil, group_by: nil)
        SumQuery.new(
          client,
          filter: filter,
          filter_params: filter_params,
          group_by: group_by,
        )
      end
    end

    class ListQuery < Sequence::Query
      def fetch(query)
        client.session.request('list-actions', query)
      end

      def translate(raw)
        Action.new(raw)
      end
    end

    class SumQuery < Sequence::Query
      def fetch(query)
        client.session.request('sum-actions', query)
      end

      def translate(raw)
        Action.new(raw)
      end
    end
  end
end
