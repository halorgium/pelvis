class Chained < Pelvis::Actor
  bind "/chained"
  operation do
    invocation.receive "starting chained"
    10.times do |number|
      invocation.request("/inner", {:number => number}, :callback => ProxyBack)
    end
  end

  module ProxyBack
    def receive(data)
      parent.receive data
    end

    def complete(data)
      parent.actor.complete(args[:number])
    end
  end

  def complete(number)
    @numbers ||= []
    @numbers << number
    check_complete
  end

  def check_complete
    if @numbers && @numbers.size == 10
      invocation.receive "completing chained"
      invocation.complete(true)
    end
  end
end
