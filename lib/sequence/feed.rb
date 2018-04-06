# frozen_string_literal: true

require 'securerandom'

require_relative './client_module'
require_relative './http_wrapper'
require_relative './query'
require_relative './response_object'

module Sequence
  class Feed < Sequence::ResponseObject
    # @!attribute [r] id
    # Unique feed identifier.
    # @return [String]
    attrib :id

    # @!attribute [r] type
    # Type of feed, "action" or "transaction".
    # @return [String]
    attrib :type

    # @!attribute [r] filter
    # The query filter used to select matching items.
    # @return [String]
    attrib :filter

    # @!attribute [r] filter_params
    # A list of values that will be interpolated into the filter expression.
    # @return [Array<String|Integer>]
    attrib :filter_params

    # @!attribute [r] cursor
    # The position where the next call to consume should begin.
    # @return [String]
    attrib :cursor

    def initialize(raw_attribs, base_session)
      super(raw_attribs)

      # The consume/ack cycle should run on its own thread, so make a copy of
      # the base connection so this feed has an exclusive HTTP connection.
      @consume_session = base_session.dup
    end

    # Consume yields successive items in a feed, waiting until at
    # least one is available (or the call times out). Since it waits
    # it may be desirable to call consume in its own thread.
    # @param [Fixnum] timeout value in seconds
    # @yieldparam object [Action, Transaction]
    # @return [void]
    def consume
      loop do
        page = @consume_session.request('stream-feed-items', id: id)

        page['items'].each_with_index do |item, index|
          @next_cursor = page['cursors'][index]
          if type == 'action'
            yield Action.new(item)
          else
            yield Transaction.new(item)
          end
        end
      end
    end

    # Ack ("acknowledge") saves a feed's position so that a future
    # call to consume picks up where the last one left off. Without
    # ack, some of the same items may be redelivered by
    # consume. Consume does its own internal acks from time to time.
    # @return [void]
    def ack
      if @next_cursor
        @consume_session.request(
          'ack-feed',
          id: id,
          cursor: @next_cursor,
          previous_cursor: cursor,
        )
        self.cursor = @next_cursor
        @next_cursor = nil
      end
    end

    class ClientModule < Sequence::ClientModule
      # Create a feed.
      # @param type [String] The type of the feed: "action" or "transaction".
      # @param id [String] A unique id for the feed.
      # @param filter [String] A valid filter string. The feed will be composed
      #   of items that match the filter.
      # @param filter_params [Array<String|Integer>] A list of values that will
      #   be interpolated into the filter expression.
      # @return [Feed] Newly created feed.
      def create(type:, id: nil, filter: nil, filter_params: nil)
        if type != 'action' && type != 'transaction'
          raise ArgumentError, ':type must equal action or transaction'
        end
        Feed.new(
          client.session.request(
            'create-feed',
            id: id,
            type: type,
            filter: filter,
            filter_params: filter_params,
          ),
          client.session,
        )
      end

      # Get feed by id.
      # @param id [String] The unique ID of a feed.
      # @return [Feed] Requested feed object.
      def get(id:)
        Feed.new(client.session.request('get-feed', id: id), client.session)
      end

      # Delete feed by id.
      # @option id [String] The unique ID of a feed.
      # @return [void]
      def delete(id:)
        client.session.request('delete-feed', id: id)
        nil
      end

      # Execute a query, returning an enumerable over individual feeds.
      # @return [Query]
      def list
        Query.new(client)
      end
    end

    class Query < Sequence::Query
      def fetch(query)
        client.session.request('list-feeds', query)
      end

      def translate(raw)
        Feed.new(raw, client.session)
      end
    end
  end
end
