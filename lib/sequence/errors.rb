module Sequence

  # Base class for all errors raised by the Sequence SDK.
  class BaseError < StandardError; end

  # InvalidRequestIDError arises when an HTTP response is received, but it does
  # not contain headers that are included in all Sequence API responses. This
  # could arise due to a badly-configured proxy, or other upstream network
  # issues.
  class InvalidRequestIDError < BaseError
    attr_accessor :response

    def initialize(response)
      super 'Response HTTP header field Chain-Request-ID is unset. There may be network issues. Please check your local network settings.'
      self.response = response
    end
  end

  # JSONError should be very rare, and will only arise if there is a bug in the
  # Sequence API, or if the upstream server is spoofing common Sequence API response
  # headers.
  class JSONError < BaseError
    attr_accessor :request_id
    attr_accessor :response

    def initialize(request_id, response)
      super "Error decoding JSON response. Request-ID: #{request_id}"
      self.request_id = request_id
      self.response = response
    end
  end

  # APIError describes errors that are codified by the Sequence API. They have
  # an error code, a message, and an optional detail field that provides
  # additional context for the error.
  class APIError < BaseError
    attr_accessor(
      :chain_message,
      :code,
      :data,
      :detail,
      :request_id,
      :response,
      :retriable,
      :temporary,
    )

    def initialize(body, response)
      self.code = body['code']
      self.chain_message = body['message']
      self.detail = body['detail']
      self.retriable = body['retriable']
      self.temporary = body['retriable']

      self.response = response
      self.request_id = response['Chain-Request-ID'] if response

      super self.class.format_error_message(code, chain_message, detail, request_id)
    end

    def retriable?
      self.retriable
    end

    def self.format_error_message(code, message, detail, request_id)
      tokens = []
      tokens << "Code: #{code}" if code.is_a?(String) && code.size > 0
      tokens << "Message: #{message}"
      tokens << "Detail: #{detail}" if detail.is_a?(String) && detail.size > 0
      tokens << "Request-ID: #{request_id}"
      tokens.join(' ')
    end
  end

  # UnauthorizedError is a special case of APIError, and is raised when the
  # response status code is 401. This is a common error case, so a discrete
  # exception type is provided for convenience.
  class UnauthorizedError < APIError; end

end
