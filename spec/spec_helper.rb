require 'rubygems'

require File.dirname(__FILE__) + '/../lib/pelvis'
require 'pelvis/protocols/xmpp'

class TestDelegate
  include Pelvis::SafeDelegate

  def initialize
    @completed, @failed = false, false
    @data = []
  end
  attr_reader :data

  def completed?
    @completed
  end

  def failed?
    @failed
  end

  def received(data)
    @data << data
  end

  def completed(event)
    @completed = event
    EM.stop
  end

  def failed(error)
    @failed = error
    EM.stop
  end
end

class Resourced < Pelvis::Actor
  def self.resources_for(op)
    case op
      when '/w_resource'
        ['/howdy']
      when '/limited_resources'
        ['/one']
      else
        nil
    end
  end

  operation "/w_resource"
  def stuff
    send_data 'message' => 'howdy'
    finish
  end

  operation "/limited_resources"
  def limited
    send_data params
    finish
  end
end

class Simple < Pelvis::Actor
  def self.resources_for(op)
    op == '/limited_resources' ? ['/two'] : nil
  end

  operation "/echo"
  def echo
    send_data params
    finish
  end

  operation "/w_resource"
  def bogus
    send_data :message => "you shouldn't get this because requests to /w_resource should have resources and hence not end up here"
    finish
  end

  operation "/limited_resources"
  def limited
    send_data params
    finish
  end

  operation "/echo_data"
  def echo_data
    recv_data do |data|
      logger.debug "echo_data recv_data: #{data.inspect}"
      send_data data
      finish
    end
  end
end

require File.dirname(__FILE__) + '/helpers'

if ENV["DEBUGGER"]
  Pelvis.logger.level = Logger::DEBUG
else
  Pelvis.logger.level = Logger::FATAL
end
