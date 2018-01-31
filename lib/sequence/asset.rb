require 'securerandom'

require_relative './client_module'
require_relative './errors'
require_relative './query'
require_relative './response_object'

module Sequence
  # A type or class of value that can be tracked on a ledger.
  class Asset < ResponseObject
    # @!attribute [r] id
    #   Unique, auto-generated identifier.
    # @return [String]
    attrib :id

    # @!attribute [r] alias
    #   Unique, user-specified identifier.
    # @return [String]
    attrib :alias

    # @!attribute [r] keys
    #   The set of keys used to sign transactions that issue the asset.
    # @return [Array<Key>]
    attrib(:keys) { |raw| raw.map { |k| Key.new(k) } }

    # @!attribute [r] quorum
    #   The number of keys required to sign transactions that issue the asset.
    # @return [Integer]
    attrib :quorum

    # @!attribute [r] tags
    #   User-specified key-value data describing the asset.
    # @return [Hash]
    attrib :tags

    class Key < ResponseObject
      attrib :id
      attrib :alias
    end

    class ClientModule < Sequence::ClientModule
      # Creates a new asset in the ledger.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] alias
      #   Unique, user-specified identifier.
      # @option opts [Array<Hash>, Array<Sequence::Key>] keys
      #   The set of keys used for signing transactions that issue the asset. A
      #   key can be either a key object, or a hash containing either an `id` or
      #   `alias` field.
      # @option opts [Integer] quorum
      #   The number of keys required to sign transactions that issue the asset.
      #   Defaults to the number of keys provided.
      # @option opts [Hash] tags
      #   User-specified key-value data describing the asset.
      # @return [Asset]
      def create(opts = {})
        validate_inclusion_of!(opts, :alias, :keys, :quorum, :tags)
        validate_required!(opts, :keys)
        Asset.new(client.session.request('create-asset', opts))
      end

      # Updates an asset's tags.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   The ID of the asset. Either an ID or alias should be provided, but not
      #   both.
      # @option opts [String] alias
      #   The alias of the asset. Either an ID or alias should be provided, but
      #   not both.
      # @option opts [Hash] tags
      #   A new set of tags, which will replace the existing tags.
      # @return [void]
      def update_tags(opts = {})
        validate_inclusion_of!(opts, :id, :alias, :tags)
        if (opts[:id].nil? || opts[:id].empty?) &&
           (opts[:alias].nil? || opts[:alias].empty?)
          raise ArgumentError, ':id or :alias (but not both) must be provided'
        end
        client.session.request('update-asset-tags', opts)
      end

      # Executes a query, returning an enumerable over individual assets.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] filter
      #   A filter expression.
      # @option opts [Array<String|Integer>] filter_params
      #   A list of values that will be interpolated into the filter expression.
      # @option opts [Integer>] page_size
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
    end

    class Query < Sequence::Query
      def fetch(query)
        client.session.request('list-assets', query)
      end

      def translate(raw)
        Asset.new(raw)
      end
    end
  end
end
