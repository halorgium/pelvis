module Pelvis
  class Agent
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(protocol, actors)
      @protocol, @actors = protocol, actors
    end
    attr_reader :protocol

    def start
      LOGGER.debug "Starting an agent: #{@protocol.inspect}, #{@actors.inspect}"
      advertise
      self
    end

    def job
      @job ||= Job.create(gen_token, "/init", {}, {}, nil)
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

    def identity
      @protocol.identity
    end

    def herault
      @protocol.herault
    end

    def actors
      @actors || []
    end

    def deliver_to(*args)
      @protocol.deliver_to(*args)
    end

    def advertise
      unless @protocol.advertise?
        LOGGER.debug "Not advertising cause I am herault"
        succeed(true)
        return
      end

      args = {:identity => identity, :operations => []}
      actors.each do |actor|
        args[:operations] += actor.provided_operations
      end
      request("/security/advertise", args, {:identities => [herault]}, self) do
        def complete(data)
          LOGGER.debug "Advertised successfully"
          parent.succeed("Advertised successfully")
        end

        def error(data)
          LOGGER.debug "Failed to advertise"
          parent.fail("Failed to advertise")
        end
      end
    end

    def evoke(evocation)
      @protocol.evoke(evocation)
    end

    def invoke(evocation)
      LOGGER.debug "running evocation: #{evocation.inspect}"
      Incall.start(self, evocation)
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
      "#<#{self.class} protocol=#{@protocol.inspect} actors=#{@actors.inspect}>"
    end
  end
end
