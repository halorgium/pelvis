require 'delegate'

module Pelvis
  class Agent
    include Logging
    extend Callbacks

    def self.readvertise_wait_interval
      @readvertise_wait_interval || 60
    end

    def self.readvertise_wait_interval=(amt)
      @readvertise_wait_interval = amt
    end

    callbacks :advertised

    def initialize(protocol)
      @protocol = protocol
    end
    attr_reader :protocol

    def start
      logger.debug "Starting an agent: #{@protocol.inspect}"
      if herault != identity
        protocol.subscribe_presence(herault) do |id, state|
          if state == :available and @advertised #should have sent our initial advertisement, we exit if we don't this prevents double initial ads
            logger.warn "Herault joined, readvertising #{identity}"
            actors.each { |a| EM.add_timer(rand(self.class.readvertise_wait_interval)) { readvertise(a) } }
          end
        end
      end
    end

    def initial_job
      @initial_job ||= Job.create(Util.gen_token, :init, "/init")
    end

    def request(scope, operation, args, options, parent = nil)
      # TODO: Shift this to the local protocol
      # serialize/unserialize attrs to wipe out symbols etc, makes locally dispatched same as remote
      args = JSON.parse(args.to_json).to_mash
      delegate = options.delete(:delegate)
      job = Job.create(Util.gen_token, scope, operation, args, options, parent || initial_job)

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

    class ConfiguredActor < SimpleDelegator
      extend Callbacks
      callbacks :readvertising

      def initialize(agent, klass, block)
        super(klass)
        @block = block || proc {|actor|}
        set_agent agent
        post_init
      end

      def post_init
        super
      end

      def start(*a)
        actor = super
        @block.call(actor)
        actor
      end

      def operations_for(job)
        super.collect {|_klass, op| [self, op]}
      end

      def readvertised_with(a)
        readvertising(a)
      end
    end

    def add_actor(klass, &block)
      actors << ConfiguredActor.new(self, klass, block)
      it = actors.last
      it.on_resources_changed {
        logger.debug "got resources changed for #{it}, readvertising"
        readvertise(it)
      }
      it
    end

    def readvertise(agent)
      logger.warn "Readvertising #{agent}"
      a = Advertiser.new(self, [agent])
      a.on_succeeded {
        logger.debug "readvertisement successful"
      }
      a.on_failed {
        logger.debug "readvertisement failed"
      }
      agent.readvertised_with(a)
    end

    def advertise
      if !@protocol.advertise? || actors.empty?
        logger.debug "Not advertising"
        advertised
        return
      end

      # initial advertisement
      a = Advertiser.new(self, actors)
      a.on_succeeded { @advertised = true; advertised }
      a.on_failed { raise "unable to perform advertisement" }
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

    def inspect
      "#<#{self.class} protocol=#{@protocol.inspect} actors=#{@actors.inspect}>"
    end
  end
end
