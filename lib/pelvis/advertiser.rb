module Pelvis
  class Advertisement
    extend Callbacks

    callbacks :received, :completed, :failed

    def initialize(advertiser, actor)
      @advertiser, @actor = advertiser, actor
    end
    attr_reader :advertiser, :actor

    def options_for_advertisement
      { :identity => agent.identity, :operations => actor.provided_operations, :resources => actor.resources }
    end

    def send
      agent.request(:direct, "/security/advertise", options_for_advertisement, :identities => [agent.herault], :delegate => self)
      self
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
        pending_advertisements << a = Advertisement.new(self, actor)
        a.send.completed { advertisement_complete(a) }
      end
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
      return true if @completed

      if @finished_advertisements >= actors.size
        completed_initial
        @completed = true
      end
    end
  end
end
