require 'json'

require_relative './http_wrapper'
require_relative './errors'
require_relative './version'

module Sequence
  # @private
  class Session
    def initialize(opts)
      @opts = opts
      @ledger = @opts[:ledger_name] || raise(ArgumentError, "missing ledger_name")
      @macaroon = @opts[:credential] || raise(ArgumentError, "missing credential")

      # Start at 0 to trigger an immediate refresh
      @refresh_at = 0

      # Expect this to get set in #refresh!
      @team_name = nil

      # This can be used to avoid making an http request to get a
      # new discharge macaroon.
      @refresh_method = @opts[:refresh_method]
      if @refresh_method
        if !@refresh_method.respond_to?(:call)
          raise(ArgumentError, "refresh_method is not a lambda")
        end
        if @refresh_method.arity != 1
          raise(ArgumentError, "refresh_method must take 1 argument. (the macaroon)")
        end
      end

      addr = ENV['SEQADDR'] || 'api.seq.com'
      @session_api = HttpWrapper.new('https://session-' + addr, nil)
      @ledger_api = HttpWrapper.new('https://' + addr, @macaroon, @opts)
    end

    def dup
      Sequence::Session.new(@opts)
    end

    def request(path, body = {})
      request_full_resp(nil, path, body)[:parsed_body]
    end

    def request_full_resp(id, path, body = {})
      refresh!(id)
      id ||= SecureRandom.hex(10)
      @ledger_api.post(id, ledger_url(path), body) do |response|
        # require that the response contains the Chain-Request-ID
        # http header. Since the Sequence API will always set this
        # header, its absence indicates that the request stopped at
        # some intermediary like a proxy on the local network or
        # a Sequence load balancer. This error will be retried by
        # HttpWrapper.post.
        req_id = response['Chain-Request-ID']
        unless req_id.is_a?(String) && req_id.size > 0
          raise InvalidRequestIDError.new(response)
        end
      end
    end

    private

    def ledger_url(path)
      path = path[1..-1] if path.start_with?("/")
      "/#{@team_name}/#{@ledger}/#{path}"
    end

    def refresh!(id)
      return if @refresh_at > Time.now.to_i

      result = if @refresh_method
        @refresh_method.call(@macaroon)
      else
        @session_api.post(id, '/sessions/validate', macaroon: @macaroon)[:parsed_body]
      end

      @team_name = result['team_name']
      @refresh_at = Integer(result['refresh_at'])
      @ledger_api.dis_macaroon = result['refresh_token']
    end
  end
end
