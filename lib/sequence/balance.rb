require_relative './client_module'
require_relative './response_object'
require_relative './query'

module Sequence
  # A summation of contract amounts. Contracts are selected using a filter, and
  # their values are summed using the common values of one or more contract
  # fields.
  # @deprecated Use {Token::ClientModule#sum} instead.
  class Balance < ResponseObject
    # @!attribute [r] amount
    #   Summation of contract amounts.
    # @return [Integer]
    attrib :amount

    # @!attribute [r] sum_by
    #   List of parameters along which contract amounts were summed.
    # @return [Hash<String => String>]
    attrib :sum_by

    class ClientModule < Sequence::ClientModule
      # Executes a query, returning an enumerable over individual balances.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Array<String>] sum_by
      #   A list of fields along which contract values will be summed.
      # @option opts [Integer>] page_size
      #   The number of items to return in the result set.
      # @return [Query]
      def query(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
          :sum_by,
          :page_size,
          :after,
        )
        Query.new(client, opts)
      end
    end

    class Query < Sequence::Query
      def fetch(query)
        client.session.request('list-balances', query)
      end

      def translate(raw)
        Balance.new(raw)
      end
    end
  end
end
