class Agent
  include EM::Deferrable

  def self.start(*args)
    new(*args).start
  end

  def initialize(router, identity)
    @router, @identity = router, identity
  end
  attr_reader :router, :identity

  def start
    LOGGER.debug "Starting an agent: #{@identity.inspect}"
    self
  end

  def request(operation, args, options, &block)
    klass = Class.new(Job, &block)
    job = klass.new(self, gen_token, operation, args, options)
    o = Outcall.start(self, job)
    o.callback do |r|
      LOGGER.debug "outcall callback: #{r.inspect}"
    end
    o.errback do |r|
      LOGGER.debug "outcall errback: #{r.inspect}"
    end
    o
  end

  def receive(type, message)
    LOGGER.debug "received message (#{type.inspect}): #{message.inspect}"
    case type
    when :init
      Incall.start(self, message)
    end
  end

  def gen_token
    HMAC::SHA256.hexdigest(Time.now.to_f.to_s, DateTime.now.ajd.to_f.to_s)
  end

  def inspect
    "#<#{self.class} router=#{@router.inspect} identity=#{@identity.inspect}>"
  end
end
