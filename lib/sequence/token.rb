require_relative './client_module'
require_relative './response_object'
require_relative './query'

module Sequence
  #  More info: {https://dashboard.seq.com/docs/tokens}
  module Token
    class ClientModule < Sequence::ClientModule
      # @param [Hash] opts
      #   Options hash.
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
        GroupQuery.new(client, opts)
      end

      # @param [Hash] opts
      #   Options hash.
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Array<String>] group_by
      #   A list of token fields to be summed.
      # @return [Query]
      def sum(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
          :group_by,
        )
        SumQuery.new(client, opts)
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
