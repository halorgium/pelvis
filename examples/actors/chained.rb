class Chained < Pelvis::Actor
  operation "/chained" do
    invocation.receive :message => "starting chained"
    number = 10
    # FIXME: changing from a timer to a 10.times loop breaks the following
    # it appears to be an issue with blather's handling of the message from jabber
    timer = EM::PeriodicTimer.new(1) {
      invocation.receive :message => "requesting inner #{number}"
      invocation.request(:all, "/inner", {:number => number}, :identities => args[:ident], :delegate => ProxyBack.new(self,number))
      number -= 1
      timer.cancel if number <= 0
    }
  end

  def complete(number)
    @numbers ||= []
    @numbers << number
    check_complete
  end

  def check_complete
    if @numbers && @numbers.size == 10
      invocation.receive :message => "completing chained"
      invocation.complete(true)
    end
  end

  class ProxyBack
    def initialize(actor, arg)
      @actor, @arg = actor, arg
    end

    def receive(data)
      @actor.invocation.receive data
    end

    def complete(data)
      @actor.complete(@arg)
    end
  end
end
