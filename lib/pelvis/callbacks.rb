module Pelvis
  module Callbacks
    def start(*args, &block)
      obj = new(*args, &block)
      EM.next_tick do
        obj.start
      end
      obj
    end

    def callbacks(*names)
      names.each do |name|
        class_eval <<-EOC, "callback on #{self} for #{name}"
          def on_#{name}(*a, &b)
            cb = EM::Callback(*a, &b)
            @_on_#{name} ||= []
            @_on_#{name} << cb
            if defined?(@_name) && @_name == #{name.to_sym.inspect}
              cb.call(*@_name_data)
            end
          end

          def #{name}(*a)
            @_name = #{name.to_sym.inspect}
            @_name_data = a
            if defined?(@_on_#{name})
              Array(@_on_#{name}).each { |cb| cb.call(*a) }
            end
            yield(*a) if block_given? # A tail run after other callbacks.
          end
        EOC
        private name
      end
    end
  end
end
