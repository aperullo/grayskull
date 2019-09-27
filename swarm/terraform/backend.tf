terraform {
  backend "s3" {
    bucket = "tf-state.gsp"
    region  = "us-gov-west-1"
    key = "swarm"
  }
}