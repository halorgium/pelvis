module Pelvis
  class Message
    def initialize(evocation, data)
      @evocation, @data = evocation, data
      @received_at = Time.now
    end
    attr_reader :evocation, :data, :received_at

    def sender
      evocation.identity
    end

    def [](key)
      data[key]
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      { :data => data, :meta => { :sender => sender, :received_at => received_at } }
    end

    def inspect
      "#<#{self.class} sender=#{sender.inspect} data=#{data.inspect}>"
    end
  end
end
