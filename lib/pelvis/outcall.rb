module Pelvis
  class Outcall
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed

    def initialize(agent, job)
      @agent, @job = agent, job
      @started_at, @finished_at = nil, nil
    end
    attr_reader :agent, :job

    def start
      logger.debug "starting outcall on #{@agent.identity}: #{inspect}"
      discover
    end

    def discover
      # TODO: Check scope here
      if identities = @job.options[:identities]
        evoke_to(identities)
      else
        discover_with_herault
      end
    end

    def discover_with_herault
      identities = []
      request = @agent.request(:direct, "/security/discover",
                               {:operation => job.operation, :need_resources => job.args[:resources]},
                               :identities => [@agent.herault])
      request.on_received do |data|
        identities += data[:identities]
      end
      request.on_completed do |event|
        evoke_to(identities)
      end
      request.on_failed do |error|
        failed("Could not do discovery: #{error}")
      end
    end

    def evoke_to(identities)
      case job.scope
      when :all
        identities.each do |i|
          evoke(i)
        end
      when :direct
        to = identities[rand(identities.size)]
        evoke(to)
      when :init
        raise "You cannot make an request with an 'init' scope"
      else
        raise "Invalid scope #{job.scope.inspect} detected"
      end
      @all_sent = true
      check_complete
    end

    def evoke(identity)
      e = Evocation.start(self, identity)
      evocations[e] = false
      e.on_received do |data|
        logger.debug "outcall received: #{identity}: #{data.inspect}"
        received(data)
      end
      e.on_completed do |event|
        logger.debug "outcall completed: #{identity}: #{event.inspect}"
        evocations[e] = true
        check_complete
      end
      e.on_failed do |error|
        logger.debug "outcall failed: #{identity}: #{error.inspect}"
        evocations[e] = true
        finish
        failed(error)
      end
    end

    def check_complete
      return unless @all_sent
      return if finished?
      if evocations.values.all?
        logger.debug "All evocations are finished"
        finish
        completed "Done at #{Time.now}"
      end
    end

    def finish
      @finished_at = Time.now
    end

    def finished?
      @finished_at
    end

    def evocations
      @evocations ||= {}
    end

    def inspect
      "#<#{self.class} agent=#{@agent.inspect} " \
        "token=#{@job.token.inspect} operation=#{@job.operation.inspect} " \
        "args=#{@job.args.inspect} options=#{@job.options.inspect}>"
    end
  end
end
