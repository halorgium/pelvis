module Pelvis
  module Protocols
    def self.available
      @available ||= {}
    end

    def self.connect(name, *args)
      name = name.to_sym
      klass = available[name] || raise("No protocol called #{name.to_sym.inspect}")
      klass.connect(*args)
    end
  end
end
