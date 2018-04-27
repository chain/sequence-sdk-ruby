# frozen_string_literal: true

require 'json'

require_relative './http_wrapper'
require_relative './errors'
require_relative './version'

module Sequence
  # @private
  class Session
    def initialize(opts)
      @opts = opts
      @ledger = @opts[:ledger_name] || raise(
        ArgumentError,
        'missing ledger_name',
      )
      @credential = @opts[:credential] || raise(
        ArgumentError,
        'missing credential',
      )
      @team_name = @opts[:team_name] || raise(
        ArgumentError,
        'missing team_name',
      )
      @ledger_api = HttpWrapper.new('https://' + @opts[:addr], @credential, @opts)
    end

    def dup
      Sequence::Session.new(@opts)
    end

    def request(path, body = {})
      request_full_resp(nil, path, body)[:parsed_body]
    end

    def request_full_resp(id, path, body = {})
      id ||= SecureRandom.hex(10)
      @ledger_api.post(id, ledger_url(path), body) do |response|
        # require that the response contains the Chain-Request-ID
        # http header. Since the Sequence API will always set this
        # header, its absence indicates that the request stopped at
        # some intermediary like a proxy on the local network or
        # a Sequence load balancer. This error will be retried by
        # HttpWrapper.post.
        req_id = response['Chain-Request-ID']
        unless req_id.is_a?(String) && !req_id.empty?
          raise InvalidRequestIDError, response
        end
      end
    end

    private

    def ledger_url(path)
      path = path[1..-1] if path.start_with?('/')
      "/#{@team_name}/#{@ledger}/#{path}"
    end
  end
end
