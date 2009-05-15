module Pelvis
  module Delegate
    def received(data)
    end

    def completed(event)
    end

    def failed(error)
    end
  end

  module SafeDelegate
    def received(data)
      raise "Implement #received in #{self.class}"
    end

    def completed(event)
      raise "Implement #completed in #{self.class}"
    end

    def failed(data)
      raise "Implement #failed in #{self.class}"
    end
  end

  class DefaultDelegate
    include Delegate
  end
end
