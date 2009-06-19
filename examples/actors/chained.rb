class Chained < Pelvis::Actor
  operation "/chained"
  def chained
    send_data :message => "starting chained"
    number = 10
    results = ProxyBack.new(self)
    # FIXME: changing from a timer to a 10.times loop breaks the following
    # it appears to be an issue with blather's handling of the message from jabber
    10.times do |number|
      send_data :message => "requesting inner #{number}"
      request(:all, "/inner", {:number => number}, :delegate => results)
    end
  end

  class ProxyBack
    include Pelvis::SafeDelegate

    def initialize(actor)
      @actor = actor
    end

    def received(data)
      @actor.send_data data
    end

    def completed(event)
      @completed ||= []
      @completed << event
      if @completed.size == 10
        @actor.finish
      end
    end
  end
end
