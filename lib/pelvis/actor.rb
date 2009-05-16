module Pelvis
  class Actor
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed

    class << self
      include Logging

      def operation(name)
        @op_for_next_method = name
      end

      # FIXME: If someone doesn't def a method after calling operation
      # @op_for_next_method will not be cleared and no error will raise
      # how can we get notified when the class finishes loading... hmmm
      def method_added(m)
        return unless name = @op_for_next_method
        @op_for_next_method = nil
        provided_operations << name
        operation_methods[name] << m
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
        # Should be overriden where appropriate, nil means don't need resources
        nil
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
      if self.class.resources
        my_resources = [params[:resources]].flatten.compact & self.class.resources
        if my_resources.empty?
          fail :code => 404, :message => "invalid resources #{params[:resources]} supplied"
        end
        params[:resources] = my_resources
      end

      send(@operation)
    rescue => e
      if @__ERROR__
        failed(@__ERROR__)
      else
        failed(:code => 500, :message => e.message)
      end
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

    def fail(data)
      @__ERROR__ = data
      raise
    end

    def failed(*args)
      @invocation.failed(*args)
    end
  end
end
