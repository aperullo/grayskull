provider "aws" {
  profile = "default"
  region  = "us-gov-west-1"
}

# This is where the state of the terraform resources are kept, in an s3 bucket.
terraform {
  backend "s3" {
    bucket = "tf-state.gsp"
    region  = "us-gov-west-1"
    key = "swarm"
  }
}


module "swarm_cluster" {
  source = "./swarm_cluster"
}
