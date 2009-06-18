module Pelvis
  class Actor
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed

    class << self
      include Logging
      extend Callbacks

      callbacks :resources_changed
      attr_reader :agent

      def post_init
        #override me
      end

      def set_agent(agent)
        @agent = agent
      end

      def operation(name, options={})
        options[:name] = name
        @op_for_next_method = options
      end

      # FIXME: If someone doesn't def a method after calling operation
      # @op_for_next_method will not be cleared and no error will raise
      # how can we get notified when the class finishes loading... hmmm
      def method_added(m)
        if defined?(@op_for_next_method) && @op_for_next_method
          op_method_added(m)
        end
      end

      def op_method_added(m)
        op, @op_for_next_method = @op_for_next_method, nil
        provided_operations << op[:name]

        operation_methods[op[:name]] = m
      end

      def lookup_op(operation)
        operation_methods[operation]
      end

      def provided_operations
        @provided_operations ||= []
      end

      def operation_methods
        @operation_methods ||= {}
      end

      def operations_for(job)
        logger.debug "searching #{provided_operations.inspect} for #{job.operation}"
        operations = []
        operation_methods.each do |operation, block|
          if operation == job.operation
            logger.debug "#{self} returning an operation: #{operation.inspect}"
            operations << [self, block]
          end
        end
        operations
      end

      def resources_for(op)
        nil
      end
    end

    # TODO: Enable config and deployment resources
    def initialize(invocation, method) #, config, deployment_resources)
      @invocation, @method = invocation, method
      @operation = self.class.operation_methods.find { |op, meth| meth == method }.first
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
      send(@method)
    end

    def validate_resources
      logger.debug "#{self.class}: resource request #{@orig_resources.inspect} we have #{resources.inspect}"
      if resources
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
      @allowed_resources ||= @orig_resources & resources
    end

    def resources
      self.class.resources_for(@operation)
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

    def recv_data(&block)
      @invocation.on_sent(&block)
    end

    def send_data(data)
      received(data)
    end

    def job
      @invocation.job
    end

    def params
      @params ||= job.args.dup
    end

    def fail(args)
      @failed = true
      failed(args)
      raise
    end

    def resources_changed
      self.class.instance_eval "resources_changed"
    end
  end
end
