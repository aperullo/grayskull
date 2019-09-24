#module "dev" {
#  source = "environments/di2e-govcloud-dev"
#}

module "staging" { 
  source = "./environments/di2e_govcloud_staging"
}


