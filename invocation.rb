class Invocation
  include EM::Deferrable

  def self.start(*args)
    new(*args).start
  end

  def initialize(incall, operation)
    @incall, @operation = incall, operation
  end
  attr_reader :incall, :operation

  def start
    LOGGER.debug "starting invocation: #{@operation.inspect}"
    @operation.call(self)
    self
  end

  def receive(data)
    LOGGER.debug "received data from operation #{@operation}: #{data.inspect}"
    @incall.receive(self, data)
  end

  def router
    @incall.router
  end

  def job
    @incall.job
  end

  def complete(data)
    LOGGER.debug "completed operation #{@operation}: #{data.inspect}"
    @complete = true
    succeed(data)
  end

  def complete?
    @complete
  end
end
