require_relative './client_module'
require_relative './session'
require_relative './query'
require_relative './response_object'

module Sequence
  # Keys are used to sign transactions.
  class Key < ResponseObject
    # @!attribute [r] id
    #   Unique identifier of the key, based on the public key material itself.
    # @return [String]
    attrib :id

    # @!attribute [r] alias
    #   Deprecated. Use {#id} instead.
    #   Unique, user-specified identifier of the key.
    # @return [String]
    attrib :alias

    class ClientModule < Sequence::ClientModule
      # Creates a key.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   Unique, user-specified identifier of the key.
      # @option opts [String] alias
      #   Deprecated. Use :id instead.
      #   Unique, user-specified identifier of the key.
      # @return [Key]
      def create(opts = {})
        validate_inclusion_of!(opts, :alias, :id)
        Key.new(client.session.request('create-key', opts))
      end

      # Executes a query, returning an enumerable over individual keys.
      # @param [Hash] opts
      #   Options hash
      # @option opts [Array<String>] aliases
      #   Deprecated. Use :ids instead.
      #   A list of aliases of keys to retrieve.
      # @option opts [Array<String>] ids
      #   A list of ids of keys to retrieve.
      # @option opts [Integer>] page_size
      #   Deprecated. Use list.page(size: size) instead.
      #   The number of items to return in the result set.
      # @return [Query]
      def query(opts = {})
        validate_inclusion_of!(opts, :aliases, :ids, :page_size, :after)
        Query.new(client, opts)
      end

      # Executes a query, returning an enumerable over individual keys.
      # @param [Hash] opts
      #   Options hash
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
        client.session.request('list-keys', query)
      end

      def translate(obj)
        Key.new(obj)
      end
    end
  end
end
