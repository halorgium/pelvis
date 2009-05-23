class Echo < Pelvis::Actor
  operation '/do/echo'
  def echo
    send_data :output => "Ready to receive data:"
    recv_data do |data|
      if "QUIT" === data[:input].chomp.upcase
        finish
      else
        send_data :output => "RECEIVED: #{data[:input]}"
      end
    end
  end
end
