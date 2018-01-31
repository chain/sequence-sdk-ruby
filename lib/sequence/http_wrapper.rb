require 'net/http'
require 'net/https'
require 'openssl'
require 'securerandom'

module Sequence
  # @private
  class HttpWrapper
    # Parameters to the retry exponential backoff function.
    RETRY_BASE_DELAY_MS = 40
    RETRY_MAX_DELAY_MS = 20_000
    RETRY_TIMEOUT_SECS = 120 # 2 minutes

    NETWORK_ERRORS = [
      InvalidRequestIDError,
      SocketError,
      EOFError,
      IOError,
      Timeout::Error,
      Errno::ECONNABORTED,
      Errno::ECONNRESET,
      Errno::ETIMEDOUT,
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
    ].freeze

    attr_accessor :dis_macaroon

    def initialize(host, macaroon, opts = {})
      @mutex = Mutex.new
      @host = URI(host)
      @macaroon = macaroon
      @dis_macaroon = nil
      @opts = opts
      @connection = setup_connection
    end

    def post(id, url, body)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      attempts = 0
      idempotency_key = SecureRandom.uuid
      begin
        attempts += 1
        # If this is a retry and not the first attempt, sleep before making the
        # retry request.
        sleep(backoff_delay(attempts)) if attempts > 1

        attempt_id = "#{id}/#{attempts}"
        @mutex.synchronize do
          req = Net::HTTP::Post.new(url)
          req.body = JSON.dump(body)
          req['Accept'] = 'application/json'
          req['Content-Type'] = 'application/json'
          req['Id'] = attempt_id
          req['Idempotency-Key'] = idempotency_key
          req['User-Agent'] = 'chain-sdk-ruby/' + Sequence::VERSION
          if !@macaroon.nil? && !@dis_macaroon.nil?
            req['Macaroon'] = @macaroon
            req['Discharge-Macaroon'] = @dis_macaroon
          end
          if !@opts[:user].nil? && !@opts[:pass].nil?
            req.basic_auth(@opts[:user], @opts[:pass])
          end
          unless @connection.started?
            @connection.start
          end
          response = @connection.request(req)

          if block_given?
            yield response
          end

          # We must parse any APIErrors here so that
          # the retry logic can handle them.
          status = Integer(response.code)
          parsed_body = nil
          if status != 204 # No Content
            begin
              parsed_body = JSON.parse(response.body)
            rescue JSON::JSONError
              raise JSONError.new(attempt_id, response)
            end
          end
          if status / 100 != 2
            klass = status == 401 ? UnauthorizedError : APIError
            raise klass.new(parsed_body, response)
          end

          { parsed_body: parsed_body, response: response }
        end
      rescue *NETWORK_ERRORS => e
        raise e if elapsed_secs(start_time) > RETRY_TIMEOUT_SECS
        retry
      rescue APIError => e
        raise e unless e.retriable?
        raise e if elapsed_secs(start_time) > RETRY_TIMEOUT_SECS
        retry
      end
    end

    private

    MILLIS_TO_SEC = 0.001

    def elapsed_secs(start_time)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    end

    def backoff_delay(attempt)
      max = RETRY_BASE_DELAY_MS * 2**(attempt - 1)
      max = [max, RETRY_MAX_DELAY_MS].min
      millis = rand(max) + 1
      millis * MILLIS_TO_SEC
    end

    def setup_connection
      args = [@host.hostname, @host.port]

      # Proxy configuration
      if @opts.key?(:proxy_addr)
        args += [@opts[:proxy_addr], @opts[:proxy_port]]
        if @opts.key?(:proxy_user)
          args += [@opts[:proxy_user], @opts[:proxy_pass]]
        end
      end

      connection = Net::HTTP.new(*args)
      connection.set_debug_output($stdout) if ENV['DEBUG']

      # TLS configuration
      connection.use_ssl = true
      connection.verify_mode = @opts[:verify_mode] || OpenSSL::SSL::VERIFY_PEER
      [:ca_file, :cert, :key].each do |k|
        next unless @opts.key?(:ssl_params) && @opts[:ssl_params].key?(k)
        connection.send("#{k}=", @opts[:ssl_params][k])
      end

      # Timeout configuration
      [:open_timeout, :read_timeout, :ssl_timeout].each do |k|
        next unless @opts.key?(k)
        connection.send "#{k}=", @opts[k]
      end

      connection
    end
  end
end
