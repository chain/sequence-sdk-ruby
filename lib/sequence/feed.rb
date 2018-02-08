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
    def consume(timeout: 24 * 60 * 60)
      loop do
        page = @consume_session.request('stream-feed-items', id: id)

        page['items'].each_with_index do |item, index|
          @next_cursor = page['cursors'][index]
          parsed = type == 'action' ? Action.new(item) : Transaction.new(item)
          yield parsed
        end

        ack
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
      # @param [Hash] opts Parameters for creating a Feed.
      # @option opts [String] id A unique id for the feed.
      # @option opts [String] type The type of the feed: "action" or "transaction".
      # @option opts [String] filter A valid filter string. The feed will be composed of items that match the filter.
      # @return [Feed] Newly created feed.
      def create(opts)
        Feed.new(client.session.request('create-feed', opts), client.session)
      end

      # Get single feed given an id.
      # @param [Hash] opts Parameters to get single feed.
      # @option opts [String] id The unique ID of a feed.
      # @return [Feed] Requested feed object.
      def get(opts)
        Feed.new(client.session.request('get-feed', opts), client.session)
      end

      # @param [Hash] opts
      # @option opts [String] :id ID of the feed.
      # @return [void]
      def delete(opts = {})
        client.session.request('delete-feed', opts)
        nil
      end

      # List all feeds
      # @return [Query]
      def query
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
