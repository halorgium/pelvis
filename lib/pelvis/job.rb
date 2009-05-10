module Pelvis
  class Job
    def initialize(agent, token, operation, args, options)
      @agent, @token, @operation, @args, @options = agent, token, operation, args, options
    end
    attr_reader :agent, :token, :operation, :args, :options

    def receive(data)
      LOGGER.debug "data: Doing nothing with #{data.inspect}"
    end

    def complete(event)
      LOGGER.debug "complete: Doing nothing with #{event.inspect}"
    end

    def error(event)
      LOGGER.debug "error: Doing nothing with #{event.inspect}"
    end
  end
end
