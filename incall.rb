class Incall
  include EM::Deferrable

  def self.start(*args)
    new(*args).start
  end

  def initialize(agent, evocation)
    @agent, @evocation = agent, evocation
  end
  attr_reader :agent, :evocation

  def start
    LOGGER.debug "starting incall on #{@agent.identity}: #{@evocation.inspect}"
    # TODO: This needs to authorize the job
    operations.each do |o|
      invoke(o)
    end
    self
  end

  def invoke(operation)
    i = Invocation.start(self, operation)
    invocations << i
    i.callback do |r|
      LOGGER.debug "callback from #{operation}: #{r.inspect}"
      check_complete
    end
    i.errback do |r|
      LOGGER.debug "errback from #{operation}: #{r.inspect}"
      check_complete
    end
  end

  def receive(invocation, data)
    LOGGER.debug "data from #{invocation.inspect}: #{data.inspect}"
    @evocation.receive(data)
  end

  def check_complete
    if invocations.all? {|e| e.complete?}
      LOGGER.debug "All invocations are finished"
      succeed "Done at #{Time.now}"
    end
  end

  def router
    @agent.router
  end

  def job
    @evocation.job
  end

  def invocations
    @invocations ||= []
  end

  # TODO: This needs to hook into the agent and locate the valid operations
  def operations
    return @operations if @operations
    @operations = []
    @operations << DoSomething
    @operations
  end

  def inspect
    "#<#{self.class} agent=#{agent.inspect} evocation=#{evocation.inspect}>"
  end
end
