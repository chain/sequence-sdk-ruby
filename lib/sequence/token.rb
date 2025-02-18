# frozen_string_literal: true

require_relative './client_module'
require_relative './response_object'
require_relative './query'

module Sequence
  #  More info: {https://dashboard.seq.com/docs/tokens}
  module Token
    class ClientModule < Sequence::ClientModule
      # Execute a query, returning an enumerable over tokens.
      # @param filter [String]
      #   A filter expression.
      # @param filter_params [Array<String|Integer>]
      #   A list of values that will be interpolated into the filter expression.
      # @return [Query]
      # @example List all tokens after a certain time
      #    ledger.tokens.list(
      #      filter: 'timestamp > $1',
      #      filter_params: ['1985-10-26T01:21:00Z']
      #    ).each do |token|
      #      puts 'amount: ' + token.amount
      #      puts 'flavor_id: ' + token.flavor_id
      #      puts 'account_id: ' + token.account_id
      #    end
      def list(filter: nil, filter_params: nil)
        GroupQuery.new(client, filter: filter, filter_params: filter_params)
      end

      # Execute a query, returning an enumerable over sums of tokens.
      # @param filter [String]
      #   A filter expression.
      # @param filter_params [Array<String|Integer>]
      #   A list of values that will be interpolated into the filter expression.
      # @param group_by [Array<String>]
      #   A list of token fields to be summed.
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

    class GroupQuery < Sequence::Query
      def fetch(query)
        client.session.request('list-tokens', query)
      end

      def translate(raw)
        Group.new(raw)
      end
    end

    class Group < Sequence::ResponseObject
      # @!attribute [r] amount
      #   The amount of tokens in the group.
      # @return [Integer]
      attrib :amount

      # @!attribute [r] flavor_id
      #   The flavor of the tokens in the group.
      # @return [String]
      attrib :flavor_id

      # @!attribute [r] flavor_tags
      #   The tags of the flavor of the tokens in the group.
      # @return [Hash]
      attrib :flavor_tags

      # @!attribute [r] account_id
      #   The account containing the tokens.
      # @return [String]
      attrib :account_id

      # @!attribute [r] account_tags
      #   The tags of the account containing the tokens.
      # @return [Hash]
      attrib :account_tags

      # @!attribute [r] tags
      #   The tags of the tokens in the group.
      # @return [Hash]
      attrib :tags
    end

    class SumQuery < Sequence::Query
      def fetch(query)
        client.session.request('sum-tokens', query)
      end

      def translate(raw)
        Sum.new(raw)
      end
    end

    class Sum < Sequence::ResponseObject
      # @!attribute [r] amount
      #   The amount of tokens in the group.
      # @return [Integer]
      attrib :amount

      # @!attribute [r] flavor_id
      #   The flavor of the tokens in the group.
      #   Is nil unless included in `group_by` request parameter.
      # @return [String]
      attrib :flavor_id

      # @!attribute [r] flavor_tags
      #   The tags of the flavor of the tokens in the group.
      #   Is nil unless included in `group_by` request parameter.
      # @return [Hash]
      attrib :flavor_tags

      # @!attribute [r] account_id
      #   The account containing the tokens.
      #   Is nil unless included in `group_by` request parameter.
      # @return [String]
      attrib :account_id

      # @!attribute [r] account_tags
      #   The tags of the account containing the tokens.
      #   Is nil unless included in `group_by` request parameter.
      # @return [Hash]
      attrib :account_tags

      # @!attribute [r] tags
      #   The tags of the tokens in the group.
      #   Is nil unless included in `group_by` request parameter.
      # @return [Hash]
      attrib :tags
    end
  end
end
