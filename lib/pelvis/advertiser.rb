module Pelvis
  class Advertisement
    include SafeDelegate

    def initialize(advertiser, actor)
      @advertiser, @actor = advertiser, actor
    end
    attr_reader :advertiser, :actor

    def options_for_advertisement
      { :identity => agent.identity, :operations => actor.provided_operations, :resources => actor.resources }
    end

    def send
      agent.request(:direct, "/security/advertise", options_for_advertisement, :identities => [agent.herault], :delegate => self)
    end

    def agent
      advertiser.agent
    end

    def completed(data)
      @advertiser.advertisement_complete(self)
    end
  end

  class Advertiser
    include Logging

    def initialize(agent, actors)
      @agent, @actors = agent, actors
      advertise
      check_complete
    end
    attr_reader :agent, :actors

    def advertise(only=nil)
      (only || actors).each do |actor|
        pending_advertisements << a = Advertisement.new(self, actor)
        a.send
      end
    end

    def pending_advertisements
      @pending_advertisements ||= []
    end

    def advertisement_complete(which)
      pending_advertisements.delete(which)
      check_complete
    end

    def check_complete
      return true if @completed

      if pending_advertisements.empty?
        @agent.advertised
        @completed = true
      end
    end
  end
end
