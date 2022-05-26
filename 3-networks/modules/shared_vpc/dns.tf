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
  parent_id   = var.parent_folder != "" ? "folders/${var.parent_folder}" : "organizations/${var.org_id}"
  policy_name = local.restricted ? "default-policy" : "dp-${var.environment_code}-shared-base-default-policy"

  google_restricted_ips = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
  google_private_ips = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
  google_dns_ips = local.restricted ? local.google_restricted_ips: local.google_private_ips

  gcr_restricted_ips = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
  gcr_private_ips = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  gcr_dns_ips = local.restricted ? local.gcr_restricted_ips : local.gcr_private_ips

  pkg_restricted_ips = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
  pkg_private_ips = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  pkg_dns_ips = local.restricted ? local.pkg_restricted_ips : local.pkg_private_ips
}

data "google_active_folder" "common" {
  display_name = "${var.folder_prefix}-common"
  parent       = local.parent_id
}

/******************************************
  DNS Hub Project
*****************************************/

data "google_projects" "dns_hub" {
  filter = "parent.id:${split("/", data.google_active_folder.common.name)[1]} labels.application_name=org-dns-hub lifecycleState=ACTIVE"
}

data "google_compute_network" "vpc_dns_hub" {
  name    = "vpc-c-dns-hub"
  project = data.google_projects.dns_hub.projects[0].project_id
}

/******************************************
  Default DNS Policy
 *****************************************/

resource "google_dns_policy" "default_policy" {
  project                   = var.project_id
  name                      = local.policy_name
  enable_inbound_forwarding = var.dns_enable_inbound_forwarding
  enable_logging            = var.dns_enable_logging
  networks {
    network_url = module.main.network_self_link
  }
}

/******************************************
  Google APIs DNS Zone & records.
 *****************************************/

module "googleapis" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 4.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${var.environment_code}-shared-${var.type}-apis"
  domain      = "googleapis.com."
  description = "Private DNS zone to configure ${var.type}.googleapis.com"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["${local.api_domain}.googleapis.com."]
    },
    {
      name    = "${local.api_domain}"
      type    = "A"
      ttl     = 300
      records = local.google_dns_ips
    },
  ]
}

/******************************************
  GCR DNS Zone & records.
 *****************************************/

module "gcr" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 3.1"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${var.environment_code}-shared-${var.type}-gcr"
  domain      = "gcr.io."
  description = "Private DNS zone to configure gcr.io"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["gcr.io."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = local.gcr_dns_ips
    },
  ]
}

/***********************************************
  Artifact Registry DNS Zone & records.
 ***********************************************/

module "pkg_dev" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 3.1"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${var.environment_code}-shared-${var.type}-pkg-dev"
  domain      = "pkg.dev."
  description = "Private DNS zone to configure pkg.dev"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["pkg.dev."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = local.pkg_dns_ips
    },
  ]
}

/******************************************
 Creates DNS Peering to DNS HUB
*****************************************/
module "peering_zone" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 3.1"
  project_id  = var.project_id
  type        = "peering"
  name        = "dz-${var.environment_code}-shared-${var.type}-to-dns-hub"
  domain      = var.domain
  description = "Private DNS peering zone."

  private_visibility_config_networks = [
    module.main.network_self_link
  ]
  target_network = data.google_compute_network.vpc_dns_hub.self_link
}
