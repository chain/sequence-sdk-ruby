# frozen_string_literal: true

require_relative './client_module'
require_relative './session'
require_relative './query'
require_relative './response_object'

module Sequence
  # Indexes are used to precompute queries that could
  # potentially be slow. When an application submits a
  # query where the filter and group-by params match
  # one of the defined indexes, the results can be
  # returned from quickly from precomputed storage.
  class Index < ResponseObject
    # @!attribute [r] id
    # Unique identifier of the index
    # @return [String]
    attrib :id

    # @!attribute [r] type
    # Type of index, "action" or "token".
    # @return [String]
    attrib :type

    # @!attribute [r] filter
    # The query filter used to select matching items.
    # @return [String]
    attrib :filter

    # @!attribute [r] group_by
    # Token/Action object fields to group by.
    # @return [Array<String>]
    attrib :group_by

    class ClientModule < Sequence::ClientModule
      # Create an index.
      # @param id [String]
      #   Unique identifier. Auto-generated if not specified.
      # @return [Index]
      def create(id: nil, type:, filter:, group_by: [])
        Index.new(client.session.request(
                    'create-index',
                    id: id,
                    type: type,
                    filter: filter,
                    group_by: group_by,
                  ))
      end

      # Delete index by id.
      # @option id [String] The unique ID of an index.
      # @return [void]
      def delete(id:)
        client.session.request('delete-index', id: id)
        nil
      end

      # List all indexes.
      # Executes a query, returning an enumerable over individual indexes.
      # @return [Query]
      def list
        Query.new(client)
      end
    end

    class Query < Sequence::Query
      def fetch(query)
        client.session.request('list-indexes', query)
      end

      def translate(obj)
        Index.new(obj)
      end
    end
  end
end
