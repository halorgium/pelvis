class Chained < Pelvis::Actor
  operation "/chained" do
    send_data :message => "starting chained"
    number = 10
    # FIXME: changing from a timer to a 10.times loop breaks the following
    # it appears to be an issue with blather's handling of the message from jabber
    timer = EM::PeriodicTimer.new(1) {
      send_data :message => "requesting inner #{number}"
      request(:all, "/inner", {:number => number}, :delegate => ProxyBack.new(self))
      number -= 1
      timer.cancel if number <= 0
    }
  end

  class ProxyBack
    def initialize(actor)
      @actor = actor
    end

    def received(data)
      @actor.send_data data
    end

    def completed(event)
      @actor.finish
    end
  end
end
