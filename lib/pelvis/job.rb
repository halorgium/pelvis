module Pelvis
  class Job
    def self.create(token, scope, operation, args, options, parent, &block)
      mod = options[:callback]
      raise "Do not specify a callback module and a block" if mod && block_given?

      klass = Job
      if block_given?
        klass = Class.new(Job, &block)
      end
      if mod && mod.kind_of?(Module)
        options.delete(:callback)
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

      @delegate = options[:callback] if options[:callback]
      @token, @scope, @operation, @args, @options, @parent = token, scope, operation, args, options, parent
      @token << ":#{@parent.job.token}" if @parent
    end
    attr_reader :token, :scope, :operation, :args, :options, :parent

    def receive(data)
      LOGGER.debug "data: Doing nothing with #{data.inspect}"
      delegate(:receive, data)
    end

    def complete(event)
      LOGGER.debug "complete: Doing nothing with #{event.inspect}"
      delegate(:complete, event)
    end

    def error(event)
      LOGGER.debug "error: Doing nothing with #{event.inspect}"
      delegate(:error, event)
    end

    private
      def delegate(method, *args)
        if @delegate && @delegate.respond_to?(method)
          @delegate.send(method, *args)
        end
      end
  end
end
