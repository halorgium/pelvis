module Pelvis
  module Helpers
    case ENV["PROTOCOL"]
    when "xmpp"
      PROTOCOL = Protocols::XMPP
      CONFIGS = {
        :foo => {:jid => "admin@localhost/agent", :password => "testing"},
        :bar => {:jid => "dummy@localhost/agent", :password => "testing"},
        :herault => {:jid => "herault@localhost/agent", :password => "testing"},
      }
    else
      PROTOCOL = Protocols::Local
      CONFIGS = {
        :foo => {:identity => "foo"},
        :bar => {:identity => "bar"},
        :herault => {:identity => "herault"},
      }
    end

    def identity_for(name)
      PROTOCOL.new(nil, CONFIGS[name]).identity
    end

    def configs_for(agents)
      agents.map do |name,actors|
        [PROTOCOL.registered_as, CONFIGS[name], actors]
      end
    end

    def agent_start(agents, &block)
      agent_connect(configs_for(agents), &block)
    end

    def agent_connect(agents, &block)
      protocol, args, actors = *agents.shift
      connection = Pelvis.connect(protocol, args, actors) do |agent|
        if agents.empty?
          block.call(agent)
        else
          agent_connect(agents, &block)
        end
      end
      connection.errback do |data|
        raise "Error with #{protocol}: #{args.inspect}: #{data}"
      end
    end
  end
end
