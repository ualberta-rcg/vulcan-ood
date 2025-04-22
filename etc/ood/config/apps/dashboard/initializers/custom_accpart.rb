module CustomAccPart
  def self.accpart
    [
      "eureka:default:normal",     # format: cluster:partition:qos
      "eureka:gpu:normal"
    ]
  end
end
