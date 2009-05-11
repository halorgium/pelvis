module Pelvis
  class Router
    include EM::Deferrable

    def self.start
      EM.run do
        router = new
        yield router if block_given?
      end
    end

    def connect(protocol_name, protocol_options, actors = nil, &block)
      protocol = Protocols.connect(protocol_name, self, protocol_options, actors)
      protocol.callback(&block) if block_given?
      protocol.errback do |r|
        LOGGER.error "Could not connect to protocol: #{protocol.inspect}, #{r.inspect}"
      end
      protocol
    end

    def inspect
      "#<#{self.class} agents=#{agents.map {|a| a.identity}.inspect}>"
    end
  end
end
