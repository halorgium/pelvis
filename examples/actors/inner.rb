class Inner < Pelvis::Actor
  operation "/inner" do
    invocation.receive :message => "starting inner: #{invocation.job.args[:number]}"
    EM.add_timer(rand(100) / 40.0) do
      invocation.receive :message => "completing inner: #{invocation.job.args[:number]}"
      invocation.complete(true)
    end
  end
end
