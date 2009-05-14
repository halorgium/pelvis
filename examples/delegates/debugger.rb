class Debugger
  include Pelvis::Delegate

  def receive(data)
    log "Received data: #{data.inspect}"
  end

  def complete(event)
    log "Completed with #{event.inspect}"
  end

  def log(message)
    puts "%0.7f: %s" % [Time.now.to_f, message]
  end
end

