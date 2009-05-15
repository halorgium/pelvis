module Pelvis
  module Helpers
    case ENV["PROTOCOL"]
    when "xmpp"
      PROTOCOL = Protocols::XMPP
      CONFIGS = {
        :foo => {:jid => "admin@localhost/agent", :password => "testing"}.freeze,
        :bar => {:jid => "dummy@localhost/agent", :password => "testing"}.freeze,
        :herault => {:jid => "herault@localhost/agent", :password => "testing", :advertise => false}.freeze,
      }
    else
      PROTOCOL = Protocols::Local
      CONFIGS = {
        :foo => {:identity => "foo"}.freeze,
        :bar => {:identity => "bar"}.freeze,
        :herault => {:identity => "herault", :advertise => false}.freeze,
      }
    end

    def identity_for(name)
      PROTOCOL.new(CONFIGS[name]).identity
    end

    def start_agents(&block)
      EM.run do
        agent_connect(@agents, &block)
      end
    end

    def agent_connect(agents, &block)
      agent, actors = *agents.shift
      options = CONFIGS[agent].dup
      options[:advertise] = false if @disable_advertise
      connection = Pelvis.connect(PROTOCOL.registered_as, options) do |agent|
        if actors
          actors.each do |actor|
            agent.actors << actor
          end
        end

        if agents.empty?
          block.call(agent)
        else
          agent_connect(agents, &block)
        end
      end
      connection.on_failed do |error|
        raise "Error with #{connection.inspect}: #{error.inspect}"
      end
    end
  end
end
