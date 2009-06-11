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

    def start_em(after=nil)
      EM.run(nil, after) do
        Protocols::Local::SET.clear
        yield
      end
    end

    def start_agents(&block)
      start_em do
        agent_connect(@agents, &block)
      end
    end

    def connect(agent, &block)
      options = CONFIGS[agent].dup
      Pelvis.connect(PROTOCOL.registered_as, options, &block)
    end

    def agent_connect(agents, &block)
      agent, actors = *agents.shift
      connection = connect(agent) do |agent|
        actors.each do |actor|
          agent.add_actor actor
        end

        agent.on_advertised do
          if actors.empty?
            block.call(agent)
          else
            agent_connect(agents, &block)
          end
        end
      end
      connection.on_failed do |error|
        unless error.kind_of?(Pelvis::Protocols::XMPP::ConnectionError)
          raise "Error with #{connection.inspect}: #{error.inspect}"
        end
      end
    end

    def should_be_good(results, exp_response=nil)
      exp_response ||= [{ 'number' => 1, 'hash' => { 'one' => 2 } }]
      results.should be_completed
      results.should_not be_failed

      # We need to make sure each expected response is in the dataset
      # nothing more, order is unpredictable
      exp_response.each do |data|
        results.data.should include(data)
        results.data.delete_at results.data.index(data)
      end
      results.data.should be_empty #by now
    end

    def should_not_be_good(results)
      results.should be_failed
    end
  end
end
