require File.dirname(__FILE__) + '/spec_helper'

if ENV["PROTOCOL"] == 'xmpp'
  describe "An xmpp connection" do
    it "should fail if credentials are wrong" do
      err = []
      EM.run {
        p = Pelvis.connect(:xmpp, :jid => 'bla@localhost/agent', :password => 'foo') { }
        p.on_failed { |e| err << e; EM.stop }
      }
      err.first.should be_a_kind_of(Blather::SASLError)
    end
  end
end
