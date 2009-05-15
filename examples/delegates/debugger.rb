class Debugger
  include Pelvis::Delegate

  def received(data)
    log "Received data: #{data.inspect}"
  end

  def completed(event)
    log "Completed with #{event.inspect}"
  end

  def failed(error)
    log "Failed with #{error.inspect}"
  end

  def log(message)
    puts "%0.7f: %s" % [Time.now.to_f, message]
  end
end

