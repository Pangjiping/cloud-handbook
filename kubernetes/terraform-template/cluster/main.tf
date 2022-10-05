terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "1.186.0"
    }
  }
}

provider "alicloud" {
  # Configuration options
}

data "alicloud_vpcs" "vpc" {
  status = "Available"
}

data "alicloud_vswitches" "vsw" {
  vpc_id = data.alicloud_vpcs.vpc.vpcs.0.id
  status = "Available"
}

data "alicloud_instance_types" "default" {
  kubernetes_node_role = "Worker"
  cpu_core_count = 4
  memory_size = 8
}

# resource "alicloud_cs_managed_kubernetes" "k8s" {
#   count = 1
#   name = "test-20221003"
#   worker_vswitch_ids = data.alicloud_vswitches.vsw.0.id
#   new_nat_gateway = true
#   pod_cidr = ""
#   service_cidr = ""
#   slb_internet_enabled = true
# }