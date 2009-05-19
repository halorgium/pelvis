require File.dirname(__FILE__) + '/spec_helper'

class FakeHerault < Pelvis::Actor
  class <<self
    def reset
      ads.clear
    end

    def ads
      @ads ||= []
    end
  end

  operation '/security/advertise'
  def advertise
    self.class.ads << params
    finish
  end
end

class FakeActor < Pelvis::Actor
  class << self
    def readvertise
      resources_changed
    end

    def reset
      @_on_resources_changed = []
    end

    def resources_for(op)
      ["/resource#{op}"]
    end
  end

  operation '/test'
  def test
  end
end

describe "An agent" do
  include Pelvis::Helpers

  before(:each) do
    FakeHerault.reset; FakeActor.reset

    @agents = [
      [:herault, [FakeHerault]],
      [:foo, [FakeActor]],
      [:bar, []]
    ]
    @ad = {"identity"=>identity_for(:foo), "operations"=>{"/test"=>["/resource/test"]}}
  end

  describe "should advertise it's resources" do
    it "when loaded into an agent" do
      start_agents do |agent|
        FakeHerault.ads.should == [@ad]
        EM.stop
      end
    end

    it "when resources_changed is called" do
      after = lambda {
        FakeHerault.ads.should == [@ad, @ad]
      }

      start_em(after) do
        connect(:herault) do |agent|
          agent.add_actor FakeHerault
        end
        connect(:foo) do |agent|
          actor = agent.add_actor(FakeActor)
          agent.on_advertised {
            FakeActor.readvertise
            actor.on_readvertising { |a|
              a.on_succeeded {
                EM.stop
              }
              a.on_failed {
                EM.stop
              }
            }
          }
        end
      end
    end
  end
end

