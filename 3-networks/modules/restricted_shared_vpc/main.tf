/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
}

module "base_env" {
  source = "../shared_vpc"

  env                                = var.env
  environment_code                   = var.environment_code
  org_id                             = var.org_id
  access_context_manager_policy_id   = var.access_context_manager_policy_id
  terraform_service_account          = var.terraform_service_account
  default_region1                    = var.default_region1
  default_region2                    = var.default_region2
  domain                             = var.domain
  parent_folder                      = var.parent_folder
  enable_hub_and_spoke               = var.enable_hub_and_spoke
  enable_partner_interconnect        = var.enable_partner_interconnect
  enable_hub_and_spoke_transitivity  = var.enable_hub_and_spoke_transitivity
  base_private_service_cidr          = var.base_private_service_cidr
  base_subnet_primary_ranges         = var.base_subnet_primary_ranges
  base_subnet_secondary_ranges       = var.base_subnet_secondary_ranges
  restricted_private_service_cidr    = var.restricted_private_service_cidr
  restricted_subnet_primary_ranges   = var.restricted_subnet_primary_ranges
  restricted_subnet_secondary_ranges = var.restricted_subnet_secondary_ranges

}


