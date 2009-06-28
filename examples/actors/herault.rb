require 'set'

class Herault < Pelvis::Actor
  def self.operation_map
    @operation_map ||= Hash.new { |h,k| h[k] = {} }
  end

  def self.handle_presence(who)
    agent.protocol.subscribe_presence who do |ident, state|
      logger.debug "Herault got presence for #{ident}, #{state}"
      expire_operations_for(ident) if state == :unavailable
    end
  end

  def self.expire_operations_for(ident)
    operation_map.each do |op, idents|
      if idents.keys.include?(ident)
        operation_map[op].delete(ident)
      end
    end
  end

  operation "/security/advertise"
  def advertise
    identity = params[:identity]
    params[:operations].each do |operation, resources|
      add_identity_for_operation(identity, operation, resources)
    end
    self.class.handle_presence(identity)

    finish
  end

  operation "/security/discover"
  def discover
    identities = identities_for(params[:operation], params[:need_resources])
    send_data :identities => identities if identities.any?
    finish
  end

  def add_identity_for_operation(identity, operation, resources)
    self.class.operation_map[operation][identity] = resources
  end

  def identities_for(operation, need_resources)
    need_resources ||= []
    bla = self.class.operation_map[operation].collect do |ident, resources|
      if need_resources.empty? && !resources
        ident
      elsif resources
        (need_resources & resources).empty? ? nil : ident
      else
        nil
      end
    end.compact
    bla
  end
end
