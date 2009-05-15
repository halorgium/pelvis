module Pelvis
  module Protocols
    def self.available
      @available ||= {}
    end

    def self.start(name, *args, &block)
      name = name.to_sym
      klass = available[name] || raise("No protocol called #{name.to_sym.inspect}")
      klass.start(*args, &block)
    end
  end
end
