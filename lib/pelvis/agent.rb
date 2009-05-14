module Pelvis
  class Agent
    include Logging
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(protocol, actors)
      @protocol, @actors = protocol, actors
    end
    attr_reader :protocol

    def start
      logger.debug "Starting an agent: #{@protocol.inspect}, #{@actors.inspect}"
      succeed("Advertised successfully")
      #advertise
      self
    end

    def job
      @job ||= Job.create(gen_token, :init, "/init", {}, :delegate => DefaultDelegate.new)
    end

    def request(scope, operation, args, options)
      job = Job.create(gen_token, scope, operation, args, options)
      o = Outcall.start(self, job)
      o.callback do |r|
        logger.debug "outcall callback: #{r.inspect}"
      end
      o.errback do |r|
        logger.debug "outcall errback: #{r.inspect}"
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

    class Advertiser
      include Delegate
      include Logging

      def initialize(agent)
        @agent = agent
      end

      def complete(data)
        logger.debug "Advertised successfully"
        @agent.succeed("Advertised successfully")
      end

      def error(data)
        logger.debug "Failed to advertise"
        @agent.fail("Failed to advertise")
      end
    end

    def advertise
      unless @protocol.advertise?
        logger.debug "Not advertising cause I am herault"
        succeed(true)
        return
      end

      args = {:identity => identity, :operations => []}
      actors.each do |actor|
        args[:operations] += actor.provided_operations
      end
      request(:direct, "/security/advertise", args, :identities => [herault], :delegate => Advertiser.new(self))
    end

    def evoke(evocation)
      @protocol.evoke(evocation)
    end

    def invoke(evocation)
      logger.debug "running evocation: #{evocation.inspect}"
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
