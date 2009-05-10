class Evocation
  include EM::Deferrable

  def self.start(*args, &block)
    new(*args).start(&block)
  end

  def initialize(outcall, identity)
    @outcall, @identity = outcall, identity
  end
  attr_reader :outcall, :identity

  def start(&block)
    LOGGER.debug "starting evocation: #{@identity.inspect}"
    incall = router.deliver_to(@identity, :init, self)
    LOGGER.debug "got an incall: #{incall.inspect}"
    incall.callback do |data|
      LOGGER.debug "callback from incall: #{incall.inspect}: #{data.inspect}"
      complete(data)
    end
    incall.errback do |data|
      LOGGER.debug "errback from incall: #{incall.inspect}: #{data.inspect}"
      fail(data)
    end
    self
  end

  def receive(data)
    LOGGER.debug "received data from incall: #{data.inspect}"
    @outcall.receive(self, data)
  end

  def router
    @outcall.router
  end

  def job
    @outcall.job
  end

  def complete(data)
    @complete = true
    succeed(data)
  end

  def complete?
    @complete
  end

  def inspect
    "#<#{self.class} outcall=#{@outcall.inspect} identity=#{@identity.inspect}>"
  end
end
