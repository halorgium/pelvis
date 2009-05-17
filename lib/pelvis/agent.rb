require 'delegate'

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

    def initial_job
      @initial_job ||= Job.create(gen_token, :init, "/init")
    end

    def request(scope, operation, args, options, parent = nil)
      # TODO: Shift this to the local protocol
      # serialize/unserialize attrs to wipe out symbols etc, makes locally dispatched same as remote
      args = JSON.parse(args.to_json).to_mash
      delegate = options.delete(:delegate)
      job = Job.create(gen_token, scope, operation, args, options, parent || initial_job)

      o = Outcall.start(self, job)
      if delegate
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
          delegate.failed(error)
        end
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
    private :actors

    def add_actor(actor_klass)
      actors << actor_klass
      actor_klass.on_resources_changed {
        Advertiser.new(self, [actor_klass])
      }
    end

    class ConfiguredActor < SimpleDelegator
      def initialize(klass, block)
        super(klass)
        @block = block || proc {|actor|}
      end

      def start(*a)
        actor = super
        @block.call(actor)
        actor
      end

      def operations_for(job)
        super.collect {|_klass, op| [self, op]}
      end
    end

    def add_actor(klass, &block)
      actors << ConfiguredActor.new(klass, block)
    end

    def advertise
      unless @protocol.advertise?
        logger.debug "Not advertising"
        advertised
        return
      end

      @advertiser = Advertiser.new(self, actors)
      @advertiser.on_completed { advertised }
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
      logger.debug "#{identity}: actors #{@actors.inspect}"
      @actors.each do |actor|
        operations += actor.operations_for(job)
      end
      operations
    end

    def gen_token
      values = [
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x1000000),
        rand(0x1000000),
      ]
      "%04x%04x%04x%04x%04x%06x%06x" % values
    end

    def inspect
      "#<#{self.class} protocol=#{@protocol.inspect} actors=#{@actors.inspect}>"
    end
  end
end
