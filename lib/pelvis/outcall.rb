module Pelvis
  class Outcall
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed, :evoked

    def initialize(agent, job)
      @agent, @job = agent, job
      @started_at, @finished_at, @retried_times = nil, nil, 0
    end
    attr_reader :agent, :job, :retried_times

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
        if identities.empty?
          failed("No identities found to satisfy #{job.operation} with resources #{job.args[:resources]}")
        else
          evoke_to(identities)
        end
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
      evocations[e] = :created
      e.on_begun do
        logger.debug "outcall begun: #{identity}"
        evocations[e] = :begun
        check_begun
      end
      e.on_received do |data|
        logger.debug "outcall received: #{identity}: #{data.inspect}"
        received(data)
      end
      e.on_completed do |event|
        logger.debug "outcall completed: #{identity}: #{event.inspect}"
        evocations[e] = :finished
        check_complete
      end
      e.on_failed do |error|
        logger.warn "Outcall to #{identity} failed: #{error.inspect}"
        if can_retry?(error)
          evocations.delete(e)
          time = 2 ** (@retried_times + 1)
          logger.debug "Waiting #{time} seconds before retrying"
          EM.add_timer(time) { @retried_times += 1; evoke(identity) }
        else
          evocations[e] = :finished
          finish
          failed(error)
        end
      end
    end

    def can_retry?(error)
      if error[:type] == 'wait' and retried_times < max_retries
        logger.warn "Can Retry #{max_retries - retried_times} times"
        return true
      end
      false
    end

    def max_retries
      5
    end

    def check_begun
      return unless @all_sent
      return if finished?
      if evocations.values.any? {|s| s != :created}
        logger.debug "All evocations are begun"
        evoked
      end
    end

    def check_complete
      return unless @all_sent
      return if finished?
      if evocations.values.all? {|s| s == :finished}
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

    def put(data)
      logger.debug "outcall put: #{data.inspect}"
      evocations.each do |e, state|
        # TODO: Probably should create a timer if the state is :started
        # TODO: Probably should error somehow if the state is :finished
        e.put(data) if state == :begun
      end
    end

    def inspect
      "#<#{self.class} agent=#{@agent.inspect} " \
        "token=#{@job.token.inspect} operation=#{@job.operation.inspect} " \
        "args=#{@job.args.inspect} options=#{@job.options.inspect}>"
    end
  end
end
