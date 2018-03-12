# frozen_string_literal: true

require 'securerandom'

require_relative './client_module'
require_relative './errors'
require_relative './query'
require_relative './response_object'

module Sequence
  # A type or class of value that can be tracked on a ledger.
  class Flavor < ResponseObject
    # @!attribute [r] id
    #   Unique, auto-generated identifier.
    # @return [String]
    attrib :id

    # @!attribute [r] key_ids
    #   The set of key IDs used to sign transactions that issue tokens of the
    #   flavor.
    # @return [Array<String>]
    attrib(:key_ids)

    # @!attribute [r] keys
    #   Deprecated. Use {#key_ids} instead.
    #   The set of keys used to sign transactions that issue tokens of the
    #   flavor.
    # @return [Array<Key>]
    attrib(:keys) { |raw| raw.map { |k| Key.new(k) } }

    # @!attribute [r] quorum
    #   The number of keys required to sign transactions that issue tokens of
    #   the flavor.
    # @return [Integer]
    attrib :quorum

    # @!attribute [r] tags
    #   User-specified key-value data describing the flavor.
    # @return [Hash]
    attrib :tags

    class Key < ResponseObject
      attrib :id
    end

    class ClientModule < Sequence::ClientModule
      # Creates a new flavor in the ledger.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   Unique, user-specified identifier.
      # @option opts [Array<String>] key_ids
      #   The set of key IDs used for signing transactions that issue tokens of
      #   the flavor.
      # @option opts [Array<Hash>, Array<Sequence::Key>] keys
      #   Deprecated. Use :key_ids instead.
      #   The set of keys used for signing transactions that issue tokens of the
      #   flavor. A key can be either a key object, or a hash containing an
      #   `id` field.
      # @option opts [Integer] quorum
      #   The number of keys required to sign transactions that issue tokens of
      #   the flavor. Defaults to the number of keys provided.
      # @option opts [Hash] tags
      #   User-specified key-value data describing the flavor.
      # @return [Flavor]
      def create(opts = {})
        validate_inclusion_of!(opts, :id, :key_ids, :keys, :quorum, :tags)
        if (opts[:key_ids].nil? || opts[:key_ids].empty?) &&
           (opts[:keys].nil? || opts[:keys].empty?)
          raise(
            ArgumentError,
            ':key_ids or :keys (but not both) must be provided',
          )
        end
        Flavor.new(client.session.request('create-flavor', opts))
      end

      # Updates a flavor's tags.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   The ID of the flavor.
      # @option opts [Hash] tags
      #   A new set of tags, which will replace the existing tags.
      # @return [void]
      def update_tags(opts = {})
        validate_inclusion_of!(opts, :id, :tags)
        if opts[:id].nil? || opts[:id].empty?
          raise ArgumentError, ':id must be provided'
        end
        client.session.request('update-flavor-tags', opts)
      end

      # Executes a query, returning an enumerable over individual flavors.
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
        client.session.request('list-flavors', query)
      end

      def translate(raw)
        Flavor.new(raw)
      end
    end
  end
end
