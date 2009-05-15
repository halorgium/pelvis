module Pelvis
  class Job
    def self.create(token, scope, operation, args, options)
      Job.new(token, scope, operation, args, options)
    end

    def initialize(token, scope, operation, args, options)
      scope = scope.to_sym
      unless [:init, :direct, :all].include?(scope)
        raise ArgumentError, "Scope #{scope.inspect} is not valid"
      end
      @token, @scope, @operation, @args, @options = token, scope, operation, args, options
    end
    attr_reader :token, :scope, :operation, :args, :options, :parent
  end
end
