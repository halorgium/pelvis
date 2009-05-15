class Xen < Pelvis::Agent
  operation '/slice/stop', :stop
  operation '/slice/start', :start

  def self.resources
    ['/cluster/ey/1/slice/10','/cluster/ey/1/slice/15']
  end

  def stop
  end
  
  def start
  end
end
