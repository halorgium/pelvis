module Pelvis
  class Message
    def initialize(evocation, data)
      @evocation, @data = evocation, data
    end
    attr_reader :evocation, :data

    def sender
      evocation.identity
    end

    def [](key)
      data[key]
    end

    def inspect
      "#<#{self.class} sender=#{sender.inspect} data=#{data.inspect}>"
    end
  end
end
