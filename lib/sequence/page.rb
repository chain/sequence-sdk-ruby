require_relative './response_object'

module Sequence
  # @private
  class Page < ResponseObject
    include ::Enumerable

    # @!attribute [r] items
    # List of items.
    # @return [Array]
    attrib :items

    # @!attribute [r] next
    # Deprecated. Use {#cursor} instead.
    # Query object to request next page of items.
    # @return [Hash]
    attrib :next

    # @!attribute [r] cursor
    # String encoding the query object to request the next page of items.
    # @return [String]
    attrib :cursor

    # @!attribute [r] last_page
    # Indicator of whether there are more pages to load.
    # @return [Boolean]
    attrib :last_page

    def initialize(raw_attribs, translate)
      super(raw_attribs)
      @items = @items.map { |i| translate.call(i) }
    end

    def each
      @items.to_a.each do |item|
        yield item
      end
    end
  end
end
