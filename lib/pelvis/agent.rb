module Pelvis
  class Agent
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(router, identity, actors)
      @router, @identity, @actors = router, identity, actors
    end
    attr_reader :router, :identity, :actors

    def start
      LOGGER.debug "Starting an agent: #{@identity.inspect}"
      self
    end

    def request(operation, args, options, parent = nil, &block)
      job = Job.create(gen_token, operation, args, options, parent, &block)
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

    def operations_for(job)
      operations = []
      @actors.each do |actor|
        operations += actor.operations_for(job)
      end
      operations
    end

    def gen_token
      HMAC::SHA256.hexdigest(Time.now.to_f.to_s, DateTime.now.ajd.to_f.to_s)
    end

    def inspect
      "#<#{self.class} router=#{@router.inspect} identity=#{@identity.inspect}>"
    end
  end
end
