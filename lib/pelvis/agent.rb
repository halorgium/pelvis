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

    def actors
      @actors || []
    end

    def complete
      @protocol.succeed(self)
    end

    def deliver_to(*args)
      @protocol.deliver_to(*args)
    end

    def advertise
      unless @protocol.advertise?
        LOGGER.debug "Not advertising cause I am herault"
        return
      end

      args = {:identity => identity, :operations => []}
      actors.each do |actor|
        args[:operations] += actor.provided_operations
      end
      request("/security/advertise", args, {:identities => [@protocol.herault]}, self) do
        def complete(data)
          LOGGER.debug "Advertised successfully"
          parent.complete
        end

        def error(data)
          LOGGER.debug "Failed to advertise"
        end
      end
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
      "#<#{self.class} protocol=#{@protocol.inspect} actors=#{@actors.inspect}>"
    end
  end
end
