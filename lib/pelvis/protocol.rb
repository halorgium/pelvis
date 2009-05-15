module Pelvis
  class Protocol
    include Logging
    include EM::Deferrable

    def self.register(name)
      @registered_as = name.to_sym
      Protocols.available[name.to_sym] = self
    end

    def self.registered_as
      @registered_as
    end

    def self.start(*args)
      p = new(*args)
      EM.next_tick do
        p.start
      end
      p
    end

    def self.callback(*names)
      names.each do |name|
        class_eval <<-EOC
          def on_#{name}(*a, &b)
            cb = EM::Callback(*a, &b)
            @_on_#{name} ||= []
            @on_#{name} << cb
            cb[*@_name_data] if @_name == #{name.to_sym.inspect}
          end
          def #{name}(*a)
            @_name = #{name.to_sym.inspect}
            @_name_data = a
            Array(@_on_#{name}).each { |cb| cb[*a] }
            yield(*a) if block_given? # A tail run after other callbacks.
          end
        EOC
      end
    end

    callback :configure

    def initialize(options, &block)
      @options = options
      on_configure(&block)
    end
    attr_reader :options, :agent

    def spawn
      logger.debug "Connected to protocol: #{inspect}"
      agent = Agent.start(self)
      configure(agent)
    end

    def evoke(job)
      raise "Implement #evoke on #{self.class}"
    end

    def connect
      raise "Implement #connect on #{self.class}"
    end

    def identity
      raise "Implement #identity on #{self.class}"
    end

    def herault
      raise "Implement #herault on #{self.class}"
    end

    def on_spawn(agent)
    end

    def inspect
      "#<#{self.class} name=#{self.class.registered_as.inspect} options=#{@options.inspect}>"
    end
  end
end
