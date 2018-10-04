# frozen_string_literal: true

require_relative './client_module'
require_relative './errors'
require_relative './query'
require_relative './response_object'

module Sequence
  # A container that holds tokens in a ledger.
  class Account < ResponseObject
    # @!attribute [r] id
    #   Unique identifier of the account.
    # @return [String]
    attrib :id

    # @!attribute [r] key_ids
    #   The list of IDs for the keys that control the account.
    # @return [Array<String>]
    attrib(:key_ids)

    # @!attribute [r] quorum
    #   The number of keys required to sign transactions that transfer or retire
    #   tokens from the account.
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
      # Create a new account in the ledger.
      # @param key_ids [Array<String>]
      #   The list of IDs for the keys that control the account.
      # @param id [String]
      #   Unique identifier. Auto-generated if not specified.
      # @param quorum [Integer]
      #   The number of keys required to sign transactions that transfer or
      #   retire tokens from the account. Defaults to the number of keys
      #   provided.
      # @param tags [Hash]
      #   User-specified key-value data describing the account.
      # @return [Account]
      def create(key_ids:, id: nil, quorum: nil, tags: nil)
        raise ArgumentError, ':key_ids cannot be empty' if key_ids == []
        Account.new(
          client.session.request(
            'create-account',
            id: id,
            key_ids: key_ids,
            quorum: quorum,
            tags: tags,
          ),
        )
      end

      # Update an account's tags.
      # @param id [String]
      #   The ID of the account.
      # @param tags [Hash]
      #   A new set of tags, which will replace the existing tags.
      # @return [void]
      def update_tags(id:, tags: nil)
        raise ArgumentError, ':id cannot be blank' if id == ''
        client.session.request('update-account-tags', id: id, tags: tags)
      end

      # Filter accounts.
      # @param filter [String]
      #   A filter expression.
      # @param filter_params [Array<String|Integer>]
      #   A list of values that will be interpolated into the filter expression.
      # @return [Query]
      def list(filter: nil, filter_params: nil)
        Query.new(client, filter: filter, filter_params: filter_params)
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
