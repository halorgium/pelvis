module Pelvis
  module Helpers
    case ENV["PROTOCOL"]
    when "xmpp"
      PROTOCOL = Protocols::XMPP
      CONFIGS = {
        :foo => {:jid => "dummy@localhost/agent", :password => "testing"}.freeze,
        :boo => {:jid => "dummy2@localhost/agent", :password => "testing"}.freeze,
        :bar => {:jid => "admin@localhost/agent", :password => "testing"}.freeze,
        :herault => {:jid => "herault@localhost/agent", :password => "testing", :advertise => false}.freeze,
      }
    else
      PROTOCOL = Protocols::Local
      CONFIGS = {
        :foo => {:identity => "foo"}.freeze,
        :boo => {:identity => "boo"}.freeze,
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
      connection = Pelvis.connect(PROTOCOL.registered_as, options) do |agent|
        actors.each do |actor|
          agent.actors << actor
        end

        agent.on_advertised do
          if agents.empty?
            block.call(agent)
          else
            agent_connect(agents, &block)
          end
        end
      end
      connection.on_failed do |error|
        raise "Error with #{connection.inspect}: #{error.inspect}"
      end
    end

    def should_be_good(results, exp_response=nil)
      exp_response ||= [{ 'number' => 1, 'hash' => { 'one' => 2 } }]
      results.should be_completed
      results.should_not be_failed

      results.data.should == exp_response
    end

    def should_not_be_good(results)
      results.should be_failed
    end
  end
end
