class Outcall
  include EM::Deferrable

  def self.start(*args)
    new(*args).start
  end

  def initialize(agent, job)
    @agent, @job = agent, job
  end
  attr_reader :agent, :job

  def start
    LOGGER.debug "starting outcall on #{@agent.identity}: #{inspect}"
    identities.each do |i|
      evoke(i)
    end
    self
  end

  def evoke(identity)
    e = Evocation.start(self, identity)
    evocations << e
    e.callback do |r|
      LOGGER.debug "callback from #{identity}: #{r.inspect}"
      check_complete
    end
    e.errback do |r|
      LOGGER.debug "errback from #{identity}: #{r.inspect}"
      check_complete
    end
  end

  def receive(evocation, data)
    LOGGER.debug "data from #{evocation.inspect}: #{data.inspect}"
    @job.receive(data)
  end

  def check_complete
    if evocations.all? {|e| e.complete?}
      LOGGER.debug "All evocations are complete"
      @job.complete("win")
      succeed "Done at #{Time.now}"
    end
  end

  def router
    @agent.router
  end

  def evocations
    @evocations ||= []
  end

  # TODO: This needs to support discovery
  def identities
    if identities = @job.options[:identities]
      identities
    else
      raise "You need to specify the identities until discovery works"
    end
  end

  def inspect
    "#<#{self.class} agent=#{@agent.inspect} " \
      "token=#{@token.inspect} operation=#{@operation.inspect} " \
      "args=#{@args.inspect} options=#{@options.inspect}>"
  end
end
