module Pelvis
  module Protocols
    class Local < Protocol
      include Logging

      register :local

      SET = []

      def connect
        logger.debug "connecting using #{self.class}: identity=#{identity.inspect}"
        spawn
      end

      def on_spawn(agent)
        SET << agent
      end

      def evoke(evocation)
        if agent = agent_for(evocation.identity)
          agent.invoke(evocation)
        else
          raise "Could not find an agent found #{evocation.identity.inspect}"
        end
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

      def advertise?
        identity != herault
      end
    end
  end
end
