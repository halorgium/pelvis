require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

describe "A request on pelvis" do
  include Pelvis::Helpers

  before(:each) do
    @agents = [
      [:herault,  [Herault]],
      [:foo,      [Simple]],
      [:bar,      []],
    ]
  end

  it "works when the identity is specified" do
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => [identity_for(:foo)], :delegate => results)
    end
    should_be_good(results)
  end

  it "discovers through herault when identities are not specified" do
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:all, "/number", {:number => 1, :hash => { :one => 2 }}, :delegate => results)
    end
    should_be_good(results)
  end

  it "errors when the remote end is down" do
    pending "This should call into the 'failed' callback"

    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => ["broken"], :delegate => results)
    end
    should_be_good(results)
  end

  describe "with scope" do
    before(:each) do
      @agents = [
        [:herault,  [Herault]],
        [:foo,      [Simple]],
        [:boo,      [Simple]],
        [:bar,      []],
      ]
    end

    it ":all, should send to multiple agents" do
      results = TestDelegate.new
      resp = {'number' => 1, 'other' => { 'asdf' => "foo" } }
      start_agents do |agent|
        agent.request(:all, '/number', resp, :delegate => results)
      end
      should_be_good(results, [resp,resp])
    end

    it ":direct, should send to a single agent" do
      results = TestDelegate.new
      resp = {'number' => 1, 'other' => { 'asdf' => "foo" } }
      start_agents do |agent|
        agent.request(:direct, '/number', resp, :delegate => results)
      end
      should_be_good(results, [resp])
    end
  end

  def should_be_good(results, exp_response=nil)
    exp_response ||= [{ 'number' => 1, 'hash' => { 'one' => 2 } }]
    results.should be_completed
    results.should_not be_failed

    results.data.should == exp_response
  end
end
