require_relative './response_object'

module Sequence
  # @private
  class Page < ResponseObject
    # @!attribute [r] items
    # List of items.
    # @return [Array]
    attrib :items

    # @!attribute [r] next
    # Query object to request next page of items
    # @return [Hash]
    attrib :next

    # @!attribute [r] last_page
    # Indicator of whether there are more pages to load
    # @return [Boolean]
    attrib :last_page

    def initialize(raw_attribs, translate)
      super(raw_attribs)
      @items = @items.map { |i| translate.call(i) }
    end
  end
end
