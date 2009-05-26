require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

describe "A request on pelvis" do
  include Pelvis::Helpers

  before(:each) do
    @agents = [
      [:herault,  [Herault]],
      [:foo,      [Simple]],
      [:boo,      [Resourced]],
      [:bar,      []],
    ]
  end

  it "works when the identity is specified" do
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/echo", {:number => 1, :hash => { :one => 2 }}, :identities => [identity_for(:foo)], :delegate => results)
    end
    should_be_good(results)
  end

  it "discovers through herault when identities are not specified" do
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:all, "/echo", {:number => 1, :hash => { :one => 2 }}, :delegate => results)
    end
    should_be_good(results)
  end

  it "errors when the remote end is down" do
    #pending "This should call into the 'failed' callback"

    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/echo", {:number => 1, :hash => { :one => 2 }}, :identities => ["broken@localhost"], :delegate => results)
    end
    should_not_be_good(results)
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
        agent.request(:all, '/echo', resp, :delegate => results)
      end
      should_be_good(results, [resp,resp])
    end

    it ":direct, should send to a single agent" do
      results = TestDelegate.new
      resp = {'number' => 1, 'other' => { 'asdf' => "foo" } }
      start_agents do |agent|
        agent.request(:direct, '/echo', resp, :delegate => results)
      end
      should_be_good(results, [resp])
    end
  end

  describe "that have a resource argument" do
    it "should only go to an actor that handles that resource and op" do
      results = TestDelegate.new
      start_agents do |agent|
        agent.request(:direct, '/w_resource', {:resources => ['/howdy']}, :delegate => results)
      end
      should_be_good(results, [{'message' => 'howdy'}])
    end

    it "should fail when sent to an actor that can't handle the resource" do
      results = TestDelegate.new
      start_agents do |agent|
        agent.request(:direct, '/w_resource', {:resources => ['/not_valid']}, :delegate => results)
      end
      should_not_be_good(results)
    end

    it "should be sent to multiple actors if one actor cannot handle all the resources" do
      results = TestDelegate.new
      start_agents do |agent|
        agent.request(:all, '/limited_resources', {:resources => %w(/one /two)}, :delegate => results)
      end
      should_be_good(results, [{'resources' => ['/one']}, {'resources' => ['/two']}])
    end

    it "should fail when you send a direct scoped action and one actor cannot satisfy all resources"
  end

  describe "that don't have a resource argument" do
    it "should fail when sent to an actor that uses resources" do
      results = TestDelegate.new
      start_agents do |agent|
        agent.request(:direct, '/w_resource', {:test => 'bla'}, :identities => [identity_for(:boo)], :delegate => results)
      end
      should_not_be_good(results)
    end
  end

  describe "that sends data" do
    it "should work" do
      results = TestDelegate.new
      start_agents do |agent|
        r = agent.request(:direct, '/echo_data', {}, :identities => [identity_for(:foo)], :delegate => results)
        r.on_evoked do
          r.put 'input' => 'foo'
        end
      end
      should_be_good(results, [{'input' => 'foo'}])
    end
  end

end
