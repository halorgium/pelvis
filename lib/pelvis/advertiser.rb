module Pelvis
  class Advertisement
    extend Callbacks

    callbacks :advertised

    def initialize(advertiser, actor)
      @advertiser, @actor = advertiser, actor
    end
    attr_reader :advertiser, :actor

    def start
      request = agent.request(:direct, "/security/advertise", options_for_advertisement,
                              :identities => [agent.herault])
      request.on_completed do |event|
        advertised
      end
    end

    def options_for_advertisement
      opts = { :identity => agent.identity, :operations => {} }
      actor.provided_operations.each do |op|
        opts[:operations][op] = actor.resources_for(op)
      end
      opts
    end

    def agent
      advertiser.agent
    end
  end

  class Advertiser
    include Logging
    extend Callbacks

    callbacks :completed

    def initialize(agent, actors)
      @agent, @actors = agent, actors
      @finished_advertisements = 0
      @completed = false
      advertise
    end
    attr_reader :agent, :actors

    def advertise
      actors.each do |actor|
        a = Advertisement.start(self, actor)
        pending_advertisements << a
        a.on_advertised { advertisement_complete(a) }
      end
      check_complete
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
      return if @completed

      if @finished_advertisements >= actors.size
        completed
        @completed = true
      end
    end
  end
end
