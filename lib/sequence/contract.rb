require_relative './client_module'
require_relative './response_object'
require_relative './query'

module Sequence
  # An entry in the ledger that contains value that can be spent.
  # @deprecated Use {Token::ClientModule#list} instead.
  class Contract < ResponseObject
    # @!attribute [r] id
    #   A unique ID.
    # @return [String]
    attrib :id

    # @!attribute [r] type
    #   The type of the contract. Currently, this is always "account".
    # @return [String]
    attrib :type

    # @!attribute [r] transaction_id
    #   The ID of the transaction in which the contract appears.
    # @return [String]
    attrib :transaction_id

    # @!attribute [r] asset_id
    #   The ID of the asset held by the contract.
    # @return [String]
    attrib :asset_id

    # @!attribute [r] asset_alias
    #   The alias of the asset held by the contract.
    # @return [String]
    attrib :asset_alias

    # @!attribute [r] asset_tags
    #   The tags of the asset held by the contract.
    # @return [Hash]
    attrib :asset_tags

    # @!attribute [r] amount
    #   The number of units of the asset held by the contract.
    # @return [Integer]
    attrib :amount

    # @!attribute [r] account_id
    #   The ID of the account controlling the contract.
    # @return [String]
    attrib :account_id

    # @!attribute [r] account_alias
    #   Deprecated. Use {#account_id} instead.
    #   The alias of the account controlling the contract.
    # @return [String]
    attrib :account_alias

    # @!attribute [r] account_tags
    #   The tags of the account controlling the contract.
    # @return [Hash]
    attrib :account_tags

    # @!attribute [r] reference_data
    #   User-specified key-value data embedded in the contract.
    # @return [Hash]
    attrib :reference_data

    class ClientModule < Sequence::ClientModule
      # Executes a query, returning an enumerable over individual contracts.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Integer] timestamp
      #   A millisecond Unix timestamp. Indicates that the query should be run
      #   over the state of the ledger at a given point in time.
      # @option opts [Integer>] page_size
      #   The number of items to return in the result set.
      # @return [Query]
      def query(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
          :timestamp,
          :page_size,
          :after,
        )
        Query.new(client, opts)
      end
    end

    class Query < Sequence::Query
      def fetch(query)
        client.session.request('list-contracts', query)
      end

      def translate(raw)
        Contract.new(raw)
      end
    end
  end
end
