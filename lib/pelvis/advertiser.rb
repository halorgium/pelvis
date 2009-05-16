module Pelvis
  class Advertisement
    extend Callbacks
    include SafeDelegate

    callbacks :advertised

    def initialize(advertiser, actor)
      @advertiser, @actor = advertiser, actor
    end
    attr_reader :advertiser, :actor

    def start
      agent.request(:direct, "/security/advertise", options_for_advertisement,
                    :identities => [agent.herault], :delegate => self)
    end

    def options_for_advertisement
      { :identity => agent.identity, :operations => actor.provided_operations, :resources => actor.resources }
    end

    def completed(event)
      advertised
    end

    def agent
      advertiser.agent
    end
  end

  class Advertiser
    include Logging
    extend Callbacks

    callbacks :completed_initial

    def initialize(agent, actors)
      @agent, @actors = agent, actors
      @finished_advertisements = 0
      advertise
      check_complete
    end
    attr_reader :agent, :actors

    def advertise(only=nil)
      (only || actors).each do |actor|
        a = Advertisement.start(self, actor)
        pending_advertisements << a
        a.on_advertised { advertisement_complete(a) }
      end
      @all_sent = true
    end

    def pending_advertisements
      @pending_advertisements ||= []
    end

    def advertisement_complete(which)
      pending_advertisements.delete(which)
      @finished_advertisements += 1
      check_complete
    end

    def check_complete
      return unless @all_sent
      return if @completed

      if @finished_advertisements >= actors.size
        completed_initial
        @completed = true
      end
    end
  end
end
