module Pelvis
  class Invocation
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(incall, actor_klass, operation)
      @incall, @actor_klass, @operation = incall, actor_klass, operation
      @actor = @actor_klass.new(self)
    end
    attr_reader :incall, :actor_klass, :operation, :actor

    def start
      LOGGER.debug "starting invocation: #{@actor_klass.inspect}, #{@operation.inspect}"
      @actor.run(@operation)
      self
    end

    def receive(data)
      data = data.data if data.kind_of? Message # allow passing the message object back, for chained requests
      LOGGER.debug "received data from operation #{@operation}: #{data.inspect}"
      raise "Data is not a hash: #{data.inspect}" unless data.is_a?(Hash)
      @incall.receive(self, data)
    end

    def agent
      @incall.agent
    end

    def job
      @incall.job
    end

    def request(scope, operation, args, options, &block)
      agent.request(scope, operation, args, options, self, &block)
    end

    def complete(data)
      return if complete?
      LOGGER.debug "completed operation #{@operation}: #{data.inspect}"
      @complete = true
      succeed(data)
    end

    def error(data)
      return if complete?
      LOGGER.debug "failed operation #{@operation}: #{data.inspect}"
      @complete = true
      fail(data)
    end

    def complete?
      @complete
    end
  end
end
