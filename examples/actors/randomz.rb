class Randomz < Pelvis::Actor
  bind "/do/random"
  operation do
    send_wait(rand(10))
  end

  def send_wait(number)
    @invocation.receive(:message => "data #{@invocation.job.token}")
    EM.add_timer(random_time) do
      if number == 0
        @invocation.complete("completed: #{@invocation.job.token}")
      else
        send_wait(number - 1)
      end
    end
  end

  def random_time
    rand(200) / 100.0 + 2
  end
end
