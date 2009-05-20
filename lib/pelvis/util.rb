module Pelvis
  module Util
    class << self
      def gen_token
        values = [
          rand(0x0010000),
          rand(0x0010000),
          rand(0x0010000),
          rand(0x0010000),
          rand(0x0010000),
          rand(0x1000000),
          rand(0x1000000),
        ]
        "%04x%04x%04x%04x%04x%06x%06x" % values
      end
    end
  end
end
