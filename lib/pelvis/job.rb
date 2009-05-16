module Pelvis
  class Job
    def self.create(token, scope, operation, args = {}, options = {}, parent = nil)
      new(token, scope, operation, args, options, parent)
    end

    def initialize(token, scope, operation, args, options, parent)
      scope = scope.to_sym
      unless [:init, :direct, :all].include?(scope)
        raise ArgumentError, "Scope #{scope.inspect} is not valid"
      end
      @token_parts = [token]
      @token_parts.unshift parent.token if parent
      @scope, @operation, @args, @options = scope, operation, args, options
    end
    attr_reader :scope, :operation, :args, :options, :parent

    def token
      @token ||= @token_parts.join(":")
    end
  end
end
