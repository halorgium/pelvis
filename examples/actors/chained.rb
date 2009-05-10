class Chained < Pelvis::Actor
  bind "/chained"
  operation do
    invocation.receive "starting chained"
    identities = invocation.job.args[:rcpts]
    10.times do |number|
      invocation.request("/inner", {:number => number}, :callback => ProxyBack, :identities => identities)
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

  bind "/inner"
  operation do
    invocation.receive "starting inner: #{invocation.job.args[:number]}"
    EM.add_timer(rand(100) / 40.0) do
      invocation.receive "completing inner: #{invocation.job.args[:number]}"
      invocation.complete(true)
    end
  end
end
