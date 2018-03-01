require_relative './client_module'
require_relative './errors'
require_relative './query'
require_relative './response_object'

module Sequence
  # A container for asset balances on a ledger.
  class Account < ResponseObject
    # @!attribute [r] id
    #   Unique, auto-generated identifier.
    # @return [String]
    attrib :id

    # @!attribute [r] alias
    #   Deprecated. Use {#id} instead.
    #   Unique, user-specified identifier.
    # @return [String]
    attrib :alias

    # @!attribute [r] keys
    #   The set of keys used for signing transactions that spend from the
    #   account.
    # @return [Array<Key>]
    attrib(:keys) { |raw| raw.map { |k| Key.new(k) } }

    # @!attribute [r] quorum
    #   The number of keys required to sign transactions that spend from the
    #   account.
    # @return [Integer]
    attrib :quorum

    # @!attribute [r] tags
    #   User-specified key-value data describing the account.
    # @return [Hash]
    attrib :tags

    class Key < ResponseObject
      attrib :id
      attrib :alias
    end

    class ClientModule < Sequence::ClientModule
      # Creates a new account in the ledger.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   Unique, user-specified identifier.
      # @option opts [String] alias
      #   Deprecated. Use :id instead.
      #   Unique, user-specified identifier.
      # @option opts [Array<Hash>, Array<Sequence::Key>] keys
      #   The keys used for signing transactions that spend from the account. A
      #   key can be either a key object, or a hash containing either an `id` or
      #   `alias` field.
      # @option opts [Integer] quorum
      #   The number of keys required to sign transactions that spend from the
      #   account. Defaults to the number of keys provided.
      # @option opts [Hash] tags
      #   User-specified key-value data describing the account.
      # @return [Account]
      def create(opts = {})
        validate_inclusion_of!(opts, :alias, :id, :keys, :quorum, :tags)
        validate_required!(opts, :keys)
        Account.new(client.session.request('create-account', opts))
      end

      # Updates an account's tags.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   The ID of the account. Either an ID or alias should be provided, but
      #   not both.
      # @option opts [String] alias
      #   Deprecated. Use :id instead.
      #   The alias of the account. Either an ID or alias should be provided,
      #   but not both.
      # @option opts [Hash] tags
      #   A new set of tags, which will replace the existing tags.
      # @return [void]
      def update_tags(opts = {})
        validate_inclusion_of!(opts, :id, :alias, :tags)
        if (opts[:id].nil? || opts[:id].empty?) &&
           (opts[:alias].nil? || opts[:alias].empty?)
          raise ArgumentError, ':id or :alias (but not both) must be provided'
        end
        client.session.request('update-account-tags', opts)
      end

      # Executes a query, returning an enumerable over individual accounts.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Integer>] page_size
      #   Deprecated. Use list.page(size: size) instead.
      #   The number of items to return in the result set.
      # @return [Query]
      def query(opts = {})
        validate_inclusion_of!(
          opts,
          :filter,
          :filter_params,
          :page_size,
          :after,
        )
        Query.new(client, opts)
      end

      # Filters accounts.
      #
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
        client.session.request('list-accounts', query)
      end

      def translate(raw)
        Account.new(raw)
      end
    end
  end
end
