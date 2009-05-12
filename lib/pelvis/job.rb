module Pelvis
  class Job
    def self.create(token, scope, operation, args, options, parent, &block)
      mod = options[:callback]
      raise "Do not specify a callback module and a block" if mod && block_given?

      klass = Job
      if block_given?
        klass = Class.new(Job, &block)
      end
      if mod
        klass = Class.new(Job) do
          include mod
        end
      end

      klass.new(token, scope, operation, args, options, parent)
    end

    def initialize(token, scope, operation, args, options, parent)
      scope = scope.to_sym
      unless [:init, :direct, :all].include?(scope)
        raise ArgumentError, "Scope #{scope.inspect} is not valid"
      end
      @token, @scope, @operation, @args, @options, @parent = token, scope, operation, args, options, parent
      @token << ":#{@parent.job.token}" if @parent
    end
    attr_reader :token, :scope, :operation, :args, :options, :parent

    def receive(data)
      LOGGER.debug "data: Doing nothing with #{data.inspect}"
    end

    def complete(event)
      LOGGER.debug "complete: Doing nothing with #{event.inspect}"
    end

    def error(event)
      LOGGER.debug "error: Doing nothing with #{event.inspect}"
    end
  end
end
