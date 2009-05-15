class Randomz < Pelvis::Actor
  operation "/do/random" do
    send_wait(rand(10))
  end

  def send_wait(number)
    wait = random_time
    send_data :message => "remaining #{number} waiting #{wait}"
    EM.add_timer(wait) do
      if number == 0
        finish
      else
        send_wait(number - 1)
      end
    end
  end

  def random_time
    rand(200) / 100.0 + 2
  end
end
