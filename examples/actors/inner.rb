class Inner < Pelvis::Actor
  bind "/inner"
  operation do
    invocation.receive "starting inner: #{invocation.job.args[:number]}"
    EM.add_timer(rand(100) / 40.0) do
      invocation.receive "completing inner: #{invocation.job.args[:number]}"
      invocation.complete(true)
    end
  end
end
