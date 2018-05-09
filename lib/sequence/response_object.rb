# frozen_string_literal: true

require 'json'
require 'time'

module Sequence
  class ResponseObject
    def initialize(raw_attribs)
      raw_attribs.each do |k, v|
        next unless self.class.has_attrib?(k)
        self[k] = self.class.translate(k, v) unless v.nil?
      end
    end

    def to_h
      self.class.attrib_opts.keys.each_with_object({}) do |name, memo|
        memo[name] = instance_variable_get("@#{name}")
      end
    end

    def to_json(_opts = nil)
      h = to_h.each_with_object({}) do |(k, v), memo|
        memo[k] = self.class.detranslate(k, v)
      end

      h.to_json
    end

    def [](attrib_name)
      attrib_name = attrib_name.to_sym
      unless self.class.attrib_opts.key?(attrib_name)
        raise KeyError, "key not found: #{attrib_name}"
      end

      instance_variable_get "@#{attrib_name}"
    end

    def []=(attrib_name, value)
      attrib_name = attrib_name.to_sym
      unless self.class.attrib_opts.key?(attrib_name)
        raise KeyError, "key not found: #{attrib_name}"
      end

      instance_variable_set "@#{attrib_name}", value
    end

    # @!visibility private
    def self.attrib_opts
      @attrib_opts ||= {}
    end

    # @!visibility private
    def self.attrib(attrib_name, opts = {}, &translate)
      opts[:translate] = translate
      attrib_opts[attrib_name.to_sym] = opts
      attr_accessor attrib_name
    end

    # @!visibility private
    def self.has_attrib?(attrib_name)
      attrib_opts.key?(attrib_name.to_sym)
    end

    # @!visibility private
    def self.translate(attrib_name, raw_value)
      attrib_name = attrib_name.to_sym
      opts = attrib_opts[attrib_name]

      return Snapshot.new(raw_value) if opts[:snapshot]
      return Time.parse(raw_value) if opts[:rfc3339_time]
      return raw_value if opts[:translate].nil?

      begin
        opts[:translate].call raw_value
      rescue StandardError => e
        raise TranslateError.new(attrib_name, raw_value, e)
      end
    end

    # @!visibility private
    def self.detranslate(attrib_name, raw_value)
      opts = attrib_opts.fetch(attrib_name, {})

      if opts[:rfc3339_time]
        begin
          return raw_value.to_datetime.rfc3339
        rescue StandardError => e
          raise DetranslateError.new(attrib_name, raw_value, e)
        end
      end

      raw_value
    end

    class Snapshot
      def initialize(data)
        @data = data
      end

      def [](key)
        @data[key]
      end

      def to_json(_opts = nil)
        @data.to_json
      end

      # A snapshot of the actions's tags at the time of action creation
      # @return [Hash]
      def action_tags
        @data['action_tags']
      end

      # A snapshot of the destination account's tags at the time of action
      # creation
      # @return [Hash]
      def destination_account_tags
        @data['destination_account_tags']
      end

      # A snapshot of the flavor's tags at the time of action creation
      # @return [Hash]
      def flavor_tags
        @data['flavor_tags']
      end

      # A snapshot of the source account's tags at the time of action creation
      # @return [Hash]
      def source_account_tags
        @data['source_account_tags']
      end

      # A snapshot of the token's tags at the time of action creation
      # @return [Hash]
      def token_tags
        @data['token_tags']
      end

      # A snapshot of the transaction's tags at the time of action creation
      # @return [Hash]
      def transaction_tags
        @data['transaction_tags']
      end
    end

    class TranslateError < StandardError
      attr_reader :attrib_name
      attr_reader :raw_value
      attr_reader :source

      def initialize(attrib_name, raw_value, source)
        super "Error translating attrib #{attrib_name}: #{source}"
        @attrib_name = attrib_name
        @raw_value = raw_value
        @source = source
      end
    end

    class DetranslateError < StandardError
      attr_reader :attrib_name
      attr_reader :raw_value
      attr_reader :source

      def initialize(attrib_name, raw_value, source)
        super "Error de-translating attrib #{attrib_name}: #{source}"
        @attrib_name = attrib_name
        @raw_value = raw_value
        @source = source
      end
    end
  end
end
