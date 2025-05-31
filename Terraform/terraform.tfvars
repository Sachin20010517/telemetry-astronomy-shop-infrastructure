region = "ap-southeast-1"

vpc_cidr = "10.1.0.0/16"

availability_zones = [
  "ap-southeast-1a",
  "ap-southeast-1b",
  "ap-southeast-1c"
]

private_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24",
  "10.1.3.0/24"
]

public_subnet_cidrs = [
  "10.1.4.0/24",
  "10.1.5.0/24",
  "10.1.6.0/24"
]

cluster_name    = "telemetry-astronomy-eks-cluster"
cluster_version = "1.30"

node_groups = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 2
      max_size     = 4
      min_size     = 1
    }
  }
}
