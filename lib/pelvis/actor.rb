module Pelvis
  class Actor
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed

    class << self
      include Logging

      def operation(name, method)
        provided_operations << name
        operation_methods[name] << method
      end

      def lookup_op(operation)
        operation_methods[operation]
      end

      def provided_operations
        @provided_operations ||= []
      end

      def operation_methods
        @operation_methods ||= Hash.new do |h,operation|
          h[operation] = []
        end
      end

      def operations_for(job)
        operations = []
        provided_operations.each do |operation|
          if operation == job.operation
            logger.debug "returning an operation: #{operation.inspect}"
            operation_methods[operation].each do |block|
              operations << [self, block]
            end
          end
        end
        operations
      end

      def resources
        # Should be overriden where appropriate
        []
      end
    end

    # TODO: Enable config and deployment resources
    def initialize(invocation, operation) #, config, deployment_resources)
      @invocation, @operation = invocation, operation
      @block_params = []
      #@config = config
      #@deployment_resources = deployment_resources || KeyedResources.new
    end
    attr_reader :invocation

    def start
      @started_at = Time.now
      send(@operation)
    end

    def finish
      @finished_at = Time.now
      completed "Duration: #{duration}"
    end

    def finished?
      @finished_at
    end

    def duration
      finished? ? @finished_at - @started_at : Time.now - @started_at
    end

    def request(*args)
      @invocation.request(*args)
    end

    def send_data(data)
      received(data)
    end

    def job
      @invocation.job
    end

    def params
      job.args
    end
  end
end
