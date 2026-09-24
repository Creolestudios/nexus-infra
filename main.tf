module "networking" {
  source     = "./modules/networking"
  aws_region = var.aws_region
  project    = var.project
}

module "security" {
  source      = "./modules/security"
  project     = var.project
  db_password = var.db_password
}

module "compute" {
  source                    = "./modules/compute"
  project                   = var.project
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  sg_web_id                 = module.networking.sg_web_id
  ec2_instance_profile_name = module.security.ec2_instance_profile_name
  lambda_role_arn           = module.security.lambda_role_arn
  depends_on                = [module.networking, module.security]
}

module "storage" {
  source            = "./modules/storage"
  project           = var.project
  aws_account_id    = var.aws_account_id
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  sg_rds_id         = module.networking.sg_rds_id
  sg_cache_id       = module.networking.sg_cache_id
  db_password       = var.db_password
  depends_on        = [module.networking]
}

module "monitoring" {
  source                = "./modules/monitoring"
  project               = var.project
  aws_region            = var.aws_region
  ec2_instance_id       = module.compute.ec2_instance_id
  rds_identifier        = "nexus-db-primary"
  lambda_function_names = module.compute.lambda_function_names
  alert_email           = var.alert_email
  depends_on            = [module.compute, module.storage]
}

module "billing" {
  source      = "./modules/billing"
  project     = var.project
  alert_email = var.alert_email
}
