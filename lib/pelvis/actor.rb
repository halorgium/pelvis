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
        unless defined?(@op_for_next_method) && @op_for_next_method
          return
        end
        name, @op_for_next_method = @op_for_next_method, nil
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
        logger.debug "searching #{provided_operations.inspect} for #{job.operation}"
        operations = []
        provided_operations.each do |operation|
          if operation == job.operation
            logger.debug "#{self} returning an operation: #{operation.inspect}"
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
      @orig_resources = params.delete('resources') || []
      validate_resources
      run_operation
    rescue => e
      failed(:code => 500, :message => e.message) unless @failed
    end

    def run_operation
      send(@operation)
    end

    def validate_resources
      logger.debug "#{self.class}: resource request #{@orig_resources.inspect} we have #{self.class.resources.inspect}"
      if self.class.resources
        if @orig_resources.empty?
          fail :code => 500, :message => "A resource is required for this operation"
        elsif allowed_resources.empty?
          fail :code => 404, :message => "Invalid resources #{@orig_resources.inspect} for this operation"
        end
        logger.debug "Allowing #{allowed_resources.inspect}"
        params[:resources] = allowed_resources
      elsif !@orig_resources.empty?
        fail :code => 500, :message => "This operation does not accept resources"
      end

    end

    def allowed_resources
      @allowed_resources ||= @orig_resources & self.class.resources
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

    def fail(args)
      @failed = true
      failed(args)
      raise
    end
  end
end
