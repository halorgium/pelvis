class Inner < Pelvis::Actor
  operation "/inner"
  def inner
    send_data :message => "starting inner: #{params[:number]}"
    EM.add_timer(rand(100) / 40.0) do
      send_data :message => "completing inner: #{params[:number]}"
      finish
    end
  end
end
