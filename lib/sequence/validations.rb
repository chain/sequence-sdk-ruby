module Sequence
  # Module for validating options.
  # @private
  module Validations
    private

    def validate_required!(opts, *keys)
      if keys.all? { |k| opts[k].nil? || opts[k].empty? }
        list = keys.map { |k| ":#{k}" }.join(' and ')
        raise ArgumentError, "#{list} must be provided"
      end
    end

    def validate_either!(opts, *keys)
      if keys.all? { |k| opts[k].nil? || opts[k].empty? }
        list = keys.map { |k| ":#{k}" }.join(' or ')
        raise ArgumentError, "#{list} must be provided"
      end
    end

    def validate_inclusion_of!(opts, *valid)
      opts.each_key do |key|
        next if valid.include?(key)
        list = valid.map { |v| ":#{v}" }.join(', ')
        message = ":#{key} is an invalid option. Valid options are #{list}"
        raise ArgumentError, message
      end
    end
  end
end
