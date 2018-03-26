# frozen_string_literal: true

require_relative './client_module'
require_relative './errors'
require_relative './query'
require_relative './response_object'

module Sequence
  # An account is an object in Sequence that tracks ownership of tokens on a
  # blockchain by creating and tracking control programs.
  class Account < ResponseObject
    # @!attribute [r] id
    #   Unique identifier of the account.
    # @return [String]
    attrib :id

    # @!attribute [r] key_ids
    #   The set of key IDs used for signing transactions that spend from the
    #   account.
    # @return [Array<String>]
    attrib(:key_ids)

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
    end

    class ClientModule < Sequence::ClientModule
      # Creates a new account in the ledger.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   Unique identifier. Auto-generated if not specified.
      # @option opts [Array<String>] key_ids
      #   The key IDs used for signing transactions that spend from the account.
      # @option opts [Integer] quorum
      #   The number of keys required to sign transactions that spend from the
      #   account. Defaults to the number of keys provided.
      # @option opts [Hash] tags
      #   User-specified key-value data describing the account.
      # @return [Account]
      def create(opts = {})
        validate_inclusion_of!(
          opts,
          :id,
          :key_ids,
          :quorum,
          :tags,
        )
        validate_required!(opts, :key_ids)
        Account.new(client.session.request('create-account', opts))
      end

      # Updates an account's tags.
      # @param [Hash] opts
      #   Options hash
      # @option opts [String] id
      #   The ID of the account.
      # @option opts [Hash] tags
      #   A new set of tags, which will replace the existing tags.
      # @return [void]
      def update_tags(opts = {})
        validate_inclusion_of!(opts, :id, :tags)
        validate_required!(opts, :id)
        client.session.request('update-account-tags', opts)
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
