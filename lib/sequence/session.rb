# frozen_string_literal: true

require 'json'

require_relative './http_wrapper'
require_relative './errors'
require_relative './version'
require_relative './hello'

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

      @lock = Mutex.new # protects the following instance variables
      @team_name, @addr, ttl_seconds = hello.call
      @api = api(@addr)
      @deadline = now + ttl_seconds
    end

    def dup
      Sequence::Session.new(@opts)
    end

    def request(path, body = {})
      request_full_resp(nil, path, body)[:parsed_body]
    end

    def request_full_resp(id, path, body = {})
      id ||= SecureRandom.hex(10)
      deadline = nil
      api = nil

      @lock.synchronize do
        deadline = @deadline
        api = @api
        path = "/#{@team_name}/#{@ledger}/#{path}".gsub('//', '/')
      end

      if now >= deadline
        refresh
      end

      api.post(id, path, body) do |response|
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

    def refresh
      Thread.new do
        # extend the deadline long enough to get a fresh addr
        @lock.synchronize do
          @deadline = now + HttpWrapper::RETRY_TIMEOUT_SECS
        end

        begin
          new_team_name, new_addr, ttl_seconds = hello.call
        rescue StandardError # rubocop:disable Lint/HandleExceptions
          # use existing values while trying for a successful /hello
        else
          @lock.synchronize do
            @deadline = now + ttl_seconds

            # unless addr changed, use existing API client
            # in order to re-use the TLS connection
            if @addr != new_addr
              @addr = new_addr
              @api = api(new_addr)
            end

            @team_name = new_team_name
          end
        end
      end
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i
    end

    def hello
      Sequence::Hello.new(api(ENV['SEQADDR'] || 'api.seq.com'), @ledger)
    end

    def api(addr)
      HttpWrapper.new('https://' + addr, @credential, @opts)
    end
  end
end
