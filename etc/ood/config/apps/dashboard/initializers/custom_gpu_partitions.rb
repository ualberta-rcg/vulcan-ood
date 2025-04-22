module CustomGPUPartitions
  def self.gpu_partitions
    [
      "titan",
      "gtx1080"
    ]
  end
end

module CustomGPUMappings
  def self.gpu_name_mappings
    {
      "titan" => "NVIDIA Titan",
      "gtx1080" => "NVIDIA GTX 1080"
    }
  end
end
