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
    #   A copy of the associated tags (flavor, source account, and destination
    #   account) as they existed at the time of the transaction.
    # @return [Hash]
    attrib :snapshot

    # @!attribute [r] asset_id
    #   Deprecated. Use {#flavor_id} instead
    #   The ID of the asset held by the action.
    # @return [String]
    attrib :asset_id

    # @!attribute [r] asset_alias
    #   Deprecated. Use {#flavor_id} instead
    #   The alias of the asset held by the action.
    # @return [String]
    attrib :asset_alias

    # @!attribute [r] asset_tags
    #   Deprecated. Use {#snapshot} instead
    #   The tags of the asset held by the action.
    # @return [Hash]
    attrib :asset_tags

    # @!attribute [r] source_account_id
    #   The ID of the source account executing the action.
    # @return [String]
    attrib :source_account_id

    # @!attribute [r] source_account_alias
    #   Deprecated. Use {#source_account_id} instead
    #   The alias of the source account executing the action.
    # @return [String]
    attrib :source_account_alias

    # @!attribute [r] source_account_tags
    #   Deprecated. Use {#snapshot} instead
    #   The tags of the source account executing the action.
    # @return [Hash]
    attrib :source_account_tags

    # @!attribute [r] destination_account_id
    #   The ID of the destination account affected by the action.
    # @return [String]
    attrib :destination_account_id

    # @!attribute [r] destination_account_alias
    #   Deprecated. Use {#destination_account_id} instead
    #   The alias of the destination account affected by the action.
    # @return [String]
    attrib :destination_account_alias

    # @!attribute [r] destination_account_tags
    #   Deprecated. Use {#snapshot} instead
    #   The tags of the destination account affected by the action.
    # @return [Hash]
    attrib :destination_account_tags

    # @!attribute [r] reference_data
    #   User-specified key-value data embedded in the action.
    # @return [Hash]
    attrib :reference_data

    class ClientModule < Sequence::ClientModule
      # Executes a query, returning an enumerable over individual actions.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Integer>] page_size
      #   The number of items to return in the result set.
      # @return [Query]
      # @example List all actions after a certain time
      #    ledger.actions.list(
      #      filter: 'timestamp > $1',
      #      filter_params: ['1985-10-26T01:21:00Z']
      #    ).each do |action|
      #      puts 'timestamp: ' + action.timestamp
      #      puts 'amount: ' + action.amount
      #    end
      def list(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
          :page_size,
          :after,
        )
        ListQuery.new(client, opts)
      end

      # Executes a query, returning an enumerable over individual actionsums.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Array<String>] group_by
      #   A list of fields along which action values will be summed.
      # @option opts [Integer>] page_size
      #   The number of items to return in the result set.
      # @return [Query]
      def sum(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
          :group_by,
          :page_size,
        )
        SumQuery.new(client, opts)
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
