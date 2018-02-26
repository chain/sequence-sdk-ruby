require_relative './page'

module Sequence
  class Query
    include ::Enumerable
    include Sequence::Validations

    # @private
    # @return [Client]
    attr_reader :client

    # @return [Hash]
    attr_reader :query

    def initialize(client, query = {})
      @client = client
      @query = query
    end

    # Iterate through objects in response, fetching the next page of results
    # from the API as needed.
    #
    # Implements required method
    # {https://ruby-doc.org/core/Enumerable.html Enumerable#each}.
    # @return [void]
    def each
      pages.each do |page|
        page.items.each do |item, index|
          yield item
        end
      end
    end

    # @private
    def fetch(query)
      raise NotImplementedError
    end

    # Overwrite to translate API response data to a different Ruby object.
    # @private
    def translate(response_object)
      raise NotImplementedError
    end

    alias_method :all, :to_a

    # @private
    def pages
      PageQuery.new(client, query, method(:fetch), method(:translate))
    end

    def page(opts = {})
      validate_inclusion_of!(opts, :size, :cursor)
      unless opts[:size].nil? || opts[:size].zero?
        opts[:page_size] = opts.delete(:size)
      end
      @query = @query.merge(opts)
      pages.page
    end

    # @private
    class PageQuery
      include ::Enumerable

      def initialize(client, query, fetch, translate)
        @client = client
        @query = query
        @fetch = fetch
        @translate = translate
      end

      def each
        page = nil

        loop do
          page = Page.new(@fetch.call(@query), @translate)
          @query = page.next

          yield page

          break if page.last_page

          # The second predicate (empty?) *should* be redundant, but we check it
          # anyway as a defensive measure.
          break if page.items.empty?
        end
      end

      def page
        Page.new(@fetch.call(@query), @translate)
      end

      alias_method :all, :to_a
    end
  end
end
