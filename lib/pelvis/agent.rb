module Pelvis
  class Agent
    include Logging
    extend Callbacks

    callbacks :advertised

    def initialize(protocol)
      @protocol = protocol
    end
    attr_reader :protocol

    def start
      logger.debug "Starting an agent: #{@protocol.inspect}"
    end

    def job
      @job ||= Job.create(gen_token, :init, "/init", {})
    end

    def request(scope, operation, args, options)
      # TODO: Shift this to the local protocol
      # serialize/unserialize attrs to wipe out symbols etc, makes locally dispatched same as remote
      args = JSON.parse(args.to_json).to_mash
      delegate = options.delete(:delegate)
      job = Job.create(gen_token, scope, operation, args, options)

      o = Outcall.start(self, job)
      o.on_received do |data|
        logger.debug "outcall received: #{data.inspect}"
        delegate.received(data)
      end
      o.on_completed do |event|
        logger.debug "outcall completed: #{event.inspect}"
        delegate.completed(event)
      end
      o.on_failed do |error|
        logger.debug "outcall failed: #{error.inspect}"
        delegate.failed(event)
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
      @actors ||= []
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

      def completed(data)
        logger.debug "Advertised successfully"
        @agent.advertised
      end

      def error(data)
        logger.debug "Failed to advertise"
        @agent.error
      end
    end

    def advertise
      unless @protocol.advertise?
        logger.debug "Not advertising cause I am herault"
        advertised
        return
      end

      args = {:identity => identity, :operations => []}
      actors.each do |actor|
        args[:operations] += actor.provided_operations
      end
      request(:direct, "/security/advertise", args, :identities => [herault], :delegate => Advertiser.new(self))
    end

    def evoke(identity, job)
      @protocol.evoke(identity, job)
    end

    def invoke(identity, job)
      logger.debug "running job from #{identity.inspect}: #{job.inspect}"
      Incall.start(self, identity, job)
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
