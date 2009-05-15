module Pelvis
  class Incall
    include Logging
    extend Callbacks

    callbacks :initialized, :begun, :received, :completed, :failed

    def initialize(agent, source, job)
      @agent, @source, @job = agent, source, job
    end
    attr_reader :agent, :source, :job

    def start
      logger.debug "starting incall on #{@agent.identity}: #{@job.inspect}"
      initialized
      begun
    end

    def begin
      operations.each do |o|
        invoke(*o)
      end
      check_complete
    end

    def invoke(actor_klass, operation)
      i = Invocation.start(self, actor_klass, operation)
      invocations << i
      i.on_received do |data|
        logger.debug "invocation received: #{operation}: #{data.inspect}"
        received(data)
      end
      i.on_completed do |event|
        logger.debug "invocation completed: #{operation}: #{event.inspect}"
        check_complete
      end
      i.on_failed do |error|
        logger.debug "invocation failed :#{operation}: #{error.inspect}"
        finish
        check_complete
        failed(error)
      end
    end

    def check_complete
      return if finished?
      if invocations.all? {|i| i.finished?}
        logger.debug "All invocations are finished"
        finish
        completed "Done at #{Time.now}"
      end
    end

    def finish
      @finished_at = Time.now
    end

    def finished?
      @finished_at
    end

    def router
      @agent.router
    end

    def invocations
      @invocations ||= []
    end

    def operations
      @agent.operations_for(job)
    end

    def inspect
      "#<#{self.class} agent=#{agent.inspect} job=#{job.inspect}>"
    end
  end
end
