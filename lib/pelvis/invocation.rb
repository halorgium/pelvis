module Pelvis
  class Invocation
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed, :sent

    def initialize(incall, actor_klass, operation)
      @incall, @actor_klass, @operation = incall, actor_klass, operation
      @started_at, @finished_at = nil, nil
    end
    attr_reader :incall, :actor_klass, :operation, :actor

    def start
      logger.debug "starting invocation: #{@actor_klass.inspect}, #{@operation.inspect}"
      actor = @actor_klass.start(self, @operation)
      actor.on_received do |data|
        logger.debug "operation received: #{@operation.inspect}: #{data.inspect}"
        raise "Data is not a hash: #{data.inspect}" unless data.is_a?(Hash)
        received(data)
      end
      actor.on_completed do |event|
        logger.debug "operation completed: #{@operation.inspect}: #{event.inspect}"
        finish
        completed(event)
      end
      actor.on_failed do |error|
        logger.debug "operation failed: #{@operation}: #{error.inspect}"
        finish
        failed(error)
      end
    end

    def agent
      @incall.agent
    end

    def job
      @incall.job
    end

    def request(scope, operation, args, options)
      agent.request(scope, operation, args, options, job)
    end

    def finish
      @finished_at = Time.now
    end

    def finished?
      @finished_at
    end

    def put(data)
      logger.debug "invocation put: #{data.inspect}"
      sent(data)
    end
  end
end
