module Pelvis
  module Protocols
    class Local < Protocol
      include Logging

      register :local

      SET = []
      PRESENCE_HANDLERS = Hash.new { |h,k| h[k] = [] }

      def connect
        logger.debug "connecting using #{self}: identity=#{identity.inspect}"

        call_presence_handlers(identity, :available)

        on_spawned do |agent|
          SET << agent
        end
        connected
      end

      def stop
        SET.delete(identity)
        call_presence_handlers(identity, :unavailable)
      end

      def evoke(identity, job)
        if remote_agent = agent_for(identity)
          remote_agent.invoke(agent.identity, job)
        else
          IncallProxy.start(identity, job)
        end
      end

      class IncallProxy
        extend Callbacks

        callbacks :initialized, :begun, :received, :completed, :failed

        def initialize(identity, job)
          @identity, @job = identity, job
        end

        def start
          failed(:code => 404, :message => "Could not find an agent found #{@identity.inspect}")
        end
      end

      def presence_handlers
        PRESENCE_HANDLERS
      end

      def handle_subscribe_presence(ident)
        # nothing to do
      end

      def agent_for(identity)
        SET.find do |a|
          a.identity == identity
        end
      end

      def identity
        options[:identity] || raise("Local protocol needs an identity")
      end

      def herault
        "herault"
      end
    end
  end
end
