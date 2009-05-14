module Pelvis
  module Delegate
    def receive(data)
    end

    def complete(event)
    end

    def error(event)
    end
  end

  class DefaultDelegate
    include Delegate
  end
end
