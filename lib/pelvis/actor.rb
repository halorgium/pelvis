module Pelvis
  class Actor
    class << self
      def operation(&block)
        @operations.each do |operation|
          provided_operations << operation
          operation_methods[operation] << block
        end
        @operations = nil
      end

      def bind(operation)
        @operations ||= []
        @operations << operation
      end

      def lookup_op(operation)
        operation_methods[operation]
      end

      #def provides(*args)
        #resources = args.last.is_a?(Hash) ? args.pop : {}
        #raise ArgumentError, "#{args.inspect} need to have keys for each resource" if args.any?
        #resources.each do |key,resource|
          #provided_resources.add(key, resource)
        #end
      #end

      def provided_operations
        @provided_operations ||= []
      end

      def operation_methods
        @operation_methods ||= Hash.new do |h,operation|
          h[operation] = []
        end
      end

      #def provided_resources
        #@provided_resources ||= KeyedResources.new
      #end

      def operations_for(job)
        operations = []
        provided_operations.each do |operation|
          if operation == job.operation
            LOGGER.debug "returning an operation: #{operation.inspect}"
            operation_methods[operation].each do |block|
              operations << [self, block]
            end
          end
        end
        operations
      end
    end

    # TODO: Enable config and deployment resources
    def initialize(invocation) #, config, deployment_resources)
      @invocation = invocation
      #@config = config
      #@deployment_resources = deployment_resources || KeyedResources.new
    end
    attr_reader :invocation

    def run(block)
      instance_eval(&block)
    end
  end
end
