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

    def add_actor(actor_klass)
      actors << actor_klass
    end

    def deliver_to(*args)
      @protocol.deliver_to(*args)
    end

    def advertise
      unless @protocol.advertise?
        logger.debug "Not advertising"
        advertised
        return
      end

      @advertiser = Advertiser.new(self, actors)
      @advertiser.on_completed_initial { advertised }
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
      HMAC::SHA256.hexdigest("#{rand} -- #{Time.now.to_f.to_s}", DateTime.now.ajd.to_f.to_s)
    end

    def inspect
      "#<#{self.class} protocol=#{@protocol.inspect} actors=#{@actors.inspect}>"
    end
  end
end
