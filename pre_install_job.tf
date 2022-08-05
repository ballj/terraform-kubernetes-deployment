resource "kubernetes_job_v1" "pre_install" {
  count = length(var.pre_install_job_command) > 0 ? 1 : 0
  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }
  metadata {
    namespace   = var.namespace
    name        = var.object_prefix
    labels      = local.common_labels
    annotations = var.annotations
  }
  wait_for_completion = true
  spec {
    template {
      metadata {
        labels      = local.selector_labels
        annotations = var.template_annotations
      }
      spec {
        restart_policy       = "Never"
        service_account_name = length(var.service_account_name) > 0 ? var.service_account_name : null
        node_selector        = var.node_selector
        subdomain            = var.subdomain
        dynamic "image_pull_secrets" {
          for_each = {for v in var.image_pull_secrets : v => v}
          content {
            name = image_pull_secrets.key
          }
        }
        dynamic "init_container" {
          for_each = length(var.connectivity_check) > 0 ? var.connectivity_check : []
          content {
            name  = format("connectivity-%s", contains(keys(init_container.value), "name") ? init_container.value["name"] : replace(init_container.value["hostname"], ".", "-"))
            image = format("%s:%s", var.init_connectivity_image_name, var.init_connectivity_image_tag)
            security_context {
              run_as_user = 1000
            }
            image_pull_policy = var.init_connectivity_image_pull_policy
            command           = [
              "bash", "-c", join(" ", [
                "timeout", lookup(init_container.value, "timout", 30), "bash -c",
                format("'until nc -vz -w1 %s %s 2>/dev/null; do date && sleep 1; done'", init_container.value["hostname"], init_container.value["port"]),
                format("; nc -vz -w1 %s %s", init_container.value["hostname"], init_container.value["port"])
              ])
            ]
          }
        }
        container {
          image             = format("%s:%s", var.image_name, var.image_tag)
          name              = "pre-install-jobs"
          command           = var.pre_install_job_command
          args              = var.pre_install_job_args
          image_pull_policy = var.pull_policy
          dynamic "security_context" {
            for_each = var.security_context_container_enabled ? [1] : []
            content {
              capabilities {
                add  = var.security_context_container_capabilities_add
                drop = var.security_context_container_capabilities_drop
              }
            }
          }
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          dynamic "env" {
            for_each = [
            for env_var in var.env_secret : {
              name   = env_var.name
              secret = env_var.secret
              key    = env_var.key
            }
            ]
            content {
              name = env.value["name"]
              value_from {
                secret_key_ref {
                  name = env.value["secret"]
                  key  = env.value["key"]
                }
              }
            }
          }
          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
          dynamic "volume_mount" {
            for_each = flatten([
            for pvc in var.volumes : [
            for vol_mount in pvc.mounts : {
              name       = pvc.name
              mount_path = vol_mount.mount_path
              sub_path   = lookup(vol_mount, "sub_path", "")
              read_only  = lookup(vol_mount, "read_only", false)
            }
            ]
            ])
            content {
              name       = volume_mount.value["name"]
              mount_path = volume_mount.value["mount_path"]
              sub_path   = volume_mount.value["sub_path"]
              read_only  = volume_mount.value["read_only"]
            }
          }
          dynamic "volume_mount" {
            for_each = length(var.custom_certificate_authority) > 0 ? [
            for vol_mount in [
              { "name" = "etc-ssl-certs", "path" = "/etc/ssl/certs", "ro" = "true" },
              { "name" = "etc-ssl-private", "path" = "/etc/ssl/private", "ro" = "true" },
              { "name" = "custom-ca-certificates", "path" = "/usr/local/share/ca-certificates", "ro" = "true" }
            ] : {
              name       = vol_mount.name
              mount_path = vol_mount.path
              read_only  = vol_mount.ro
            }
            ] : []
            content {
              name       = volume_mount.value["name"]
              mount_path = volume_mount.value["mount_path"]
              read_only  = volume_mount.value["read_only"]
            }
          }
        }
        dynamic "security_context" {
          for_each = var.security_context_enabled ? [1] : []
          content {
            run_as_non_root = true
            #privileged                 = false
            #allow_privilege_escalation = false
            run_as_user     = var.security_context_uid
            run_as_group    = var.security_context_gid
          }
        }
        dynamic "volume" {
          for_each = var.volumes
          content {
            name = volume.value["name"]
            dynamic "empty_dir" {
              for_each = volume.value["type"] == "empty_dir" ? [1] : []
              content {
                medium     = lookup(volume.value, "dir_medium", "")
                size_limit = lookup(volume.value, "size_limit", 0)
              }
            }
            dynamic "persistent_volume_claim" {
              for_each = volume.value["type"] == "persistent_volume_claim" ? [1] : []
              content {
                claim_name = volume.value["object_name"]
                read_only  = lookup(volume.value, "readonly", false)
              }
            }
            dynamic "config_map" {
              for_each = volume.value["type"] == "config_map" ? [1] : []
              content {
                name         = volume.value["object_name"]
                default_mode = lookup(volume.value, "default_mode", "0644")
                optional     = lookup(volume.value, "optional", "false")
              }
            }
            dynamic "secret" {
              for_each = volume.value["type"] == "secret" ? [1] : []
              content {
                secret_name  = volume.value["object_name"]
                default_mode = lookup(volume.value, "default_mode", "0644")
                optional     = lookup(volume.value, "optional", "false")
              }
            }
          }
        }
        dynamic "volume" {
          for_each = length(var.custom_certificate_authority) > 0 ? [
          for vol_name in [
            "etc-ssl-certs", "etc-ssl-private"
          ] : {
            name = vol_name
          }
          ] : []
          content {
            name = volume.value["name"]
            empty_dir {
              medium = "Memory"
            }
          }
        }
        dynamic "volume" {
          for_each = var.custom_certificate_authority
          content {
            name = "custom-ca-certificates"
            projected {
              default_mode = "0400"
              sources {
                secret {
                  name = volume.value
                }
              }
            }
          }
        }
      }
    }
  }
}
