terraform {
  required_version = ">= 0.12.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

locals {
  selector_labels = {
    "app.kubernetes.io/name"     = lookup(var.labels, "app.kubernetes.io/name", var.object_prefix)
    "app.kubernetes.io/instance" = lookup(var.labels, "app.kubernetes.io/instance", var.image_tag)
    "app.kubernetes.io/part-of"  = lookup(var.labels, "app.kubernetes.io/part-of", var.object_prefix)
  }
  common_labels = merge(var.labels, {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/component"  = "deployment"
  })
}

resource "kubernetes_deployment_v1" "deployment" {
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
  wait_for_rollout = true
  spec {
    replicas                  = var.replicas
    min_ready_seconds         = var.min_ready_seconds
    progress_deadline_seconds = var.max_ready_seconds
    revision_history_limit    = var.revision_history
    selector {
      match_labels = local.selector_labels
    }
    strategy {
      type = var.update_strategy
      dynamic "rolling_update" {
        for_each = var.update_strategy == "RollingUpdate" ? [1] : []
        content {
          max_surge       = var.update_max_surge
          max_unavailable = var.update_max_unavailable
        }
      }
    }
    template {
      metadata {
        labels      = local.selector_labels
        annotations = var.template_annotations
      }
      spec {
        enable_service_links = var.service_links
        service_account_name = length(var.service_account_name) > 0 ? var.service_account_name : null
        subdomain            = var.subdomain
        dynamic "init_container" {
          for_each = alltrue([
            var.init_volume_permissions_enabled,
            length(var.volumes) > 0,
            toset([for mount in var.volumes : mount.type]) != toset(["config_map"]),
            toset([for mount in var.volumes : mount.type]) != toset(["secret"]),
            toset([for mount in var.volumes : mount.type]) != toset(["config_map", "secret"])
          ]) ? [1] : []
          content {
            name  = "volume-permissions"
            image = format("%s:%s", var.init_volume_permissions_image_name, var.init_volume_permissions_image_tag)
            security_context {
              run_as_user = 0
            }
            command = flatten(["/bin/sh", "-c", join(" && ",
              compact(flatten([for volume in var.volumes : [
                for vol_mount in volume.mounts : [
                  format("%s%s%s", "volmount='", vol_mount.mount_path, "'; if echo $${volmount} | grep -q '\\.'; then touch $${volmount}; else /bin/mkdir -p $${volmount}; fi; unset volmount"),
                  var.security_context_enabled ? format("%s %s:%s %s", "/bin/chown -R", lookup(vol_mount, "user", var.security_context_uid), lookup(vol_mount, "group", var.security_context_gid), vol_mount.mount_path) : "",
                  contains(keys(vol_mount), "permissions") ? format("%s %s %s", "/bin/chmod", vol_mount.permissions, vol_mount.mount_path) : "",
                  contains(keys(vol_mount), "mode") ? format("%s %s %s", "/bin/chmod", vol_mount.permissions, vol_mount.mount_path) : "",
                  contains(keys(vol_mount), "user") ? format("%s %s %s", "/bin/chown", vol_mount.owner, vol_mount.mount_path) : "",
                  contains(keys(vol_mount), "group") ? format("%s %s %s", "/bin/chgrp", vol_mount.group, vol_mount.mount_path) : ""] if alltrue([
                    volume.type != "config_map",
                    volume.type != "secret"
                ])
              ]])),
            compact(flatten(var.init_volume_permissions_extraargs)))])
            dynamic "volume_mount" {
              for_each = flatten([for volume in var.volumes : [
                for vol_mount in volume.mounts : {
                  name       = volume.name
                  mount_path = vol_mount.mount_path
                  sub_path   = lookup(vol_mount, "sub_path", "")
                  read_only  = lookup(vol_mount, "read_only", "")
                }]
              ])
              content {
                name       = volume_mount.value["name"]
                mount_path = volume_mount.value["mount_path"]
                sub_path   = volume_mount.value["sub_path"]
              }
            }
          }
        }
        dynamic "init_container" {
          for_each = length(var.custom_certificate_authority) > 0 ? [1] : []
          content {
            name  = "certificates"
            image = format("%s:%s", var.init_customca_image_name, var.init_customca_image_tag)
            security_context {
              run_as_user = 0
            }
            command = ["/bin/sh", "-c", join(" && ", [
              join(" ", ["if command -v apk >/dev/null; then",
                "apk add --no-cache ca-certificates openssl && update-ca-certificates;",
              "else apt-get update && apt-get install -y ca-certificates openssl; fi"]),
              join(" ", ["openssl req -new -x509 -days 3650 -nodes -sha256",
                "-subj \"/CN=$(hostname)\" -addext \"subjectAltName = DNS:$(hostname)\"",
                "-out  /etc/ssl/certs/ssl-cert-snakeoil.pem",
              "-keyout /etc/ssl/private/ssl-cert-snakeoil.key -extensions v3_req"]),
              "chown root:root -R /etc/ssl",
              "chmod 0755 /etc/ssl/certs",
              "chmod 0700 /etc/ssl/private"
            ])]
            volume_mount {
              name       = "etc-ssl-certs"
              mount_path = "/etc/ssl/certs"
              read_only  = false
            }
            volume_mount {
              name       = "etc-ssl-private"
              mount_path = "/etc/ssl/private"
              read_only  = false
            }
            volume_mount {
              name       = "custom-ca-certificates"
              mount_path = "/usr/local/share/ca-certificates"
              read_only  = true
            }
            dynamic "env" {
              for_each = [for env_var in var.init_customca_env_secret : {
                name   = env_var.name
                secret = env_var.secret
                key    = env_var.key
              }]
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
          }
        }
        dynamic "init_container" {
          for_each = alltrue([length(var.init_user_image_name) > 0, length(var.init_user_image_tag) > 0]) ? [1] : []
          content {
            name              = "user"
            image             = format("%s:%s", var.init_user_image_name, var.init_user_image_tag)
            image_pull_policy = var.init_user_image_pull_policy
            security_context {
              run_as_user  = var.init_user_security_context_uid
              run_as_group = var.init_user_security_context_gid
            }
            command = var.init_user_command
            dynamic "env" {
              for_each = [for env_var in var.init_user_env_secret : {
                name   = env_var.name
                secret = env_var.secret
                key    = env_var.key
              }]
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
            dynamic "volume_mount" {
              for_each = flatten([for volume in var.volumes : [
                for vol_mount in volume.mounts : {
                  name       = volume.name
                  mount_path = vol_mount.mount_path
                  sub_path   = lookup(vol_mount, "sub_path", "")
                  read_only  = lookup(vol_mount, "read_only", "")
                } if lookup(vol_mount, "init_user_enabled", true)]
              ])
              content {
                name       = volume_mount.value["name"]
                mount_path = volume_mount.value["mount_path"]
                sub_path   = volume_mount.value["sub_path"]
              }
            }
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
            command = [
              "bash", "-c", join(" ", ["timeout", lookup(init_container.value, "timout", 30), "bash -c",
                format("'until nc -vz -w1 %s %s 2>/dev/null; do date && sleep 1; done'", init_container.value["hostname"], init_container.value["port"]),
              format("; nc -vz -w1 %s %s", init_container.value["hostname"], init_container.value["port"])])
            ]
          }
        }
        container {
          image             = format("%s:%s", var.image_name, var.image_tag)
          name              = regex("[[:alnum:]]+$", var.image_name)
          command           = var.command
          args              = var.arguments
          image_pull_policy = var.pull_policy
          lifecycle {
            dynamic "post_start" {
              for_each = length(var.post_start_type) > 0 ? [1] : []
              content {
                dynamic "exec" {
                  for_each = var.post_start_type == "exec" ? [1] : []
                  content {
                    command = var.post_start_command
                  }
                }
                dynamic "http_get" {
                  for_each = var.post_start_type == "http_get" ? [1] : []
                  content {
                    host = var.post_start_host
                    dynamic "http_header" {
                      for_each = length(var.post_start_http_header) > 0 ? var.post_start_http_header : []
                      content {
                        name  = http_header.value["name"]
                        value = http_header.value["value"]
                      }
                    }
                    path   = var.post_start_path
                    port   = var.post_start_port > 0 ? var.post_start_port : lookup({ for port in var.ports : lower(port.name) => port.container_port }, lower(var.post_start_scheme), var.ports[0].container_port)
                    scheme = var.post_start_scheme
                  }
                }
                dynamic "tcp_socket" {
                  for_each = var.post_start_type == "tcp_socket" ? [1] : []
                  content {
                    port = var.post_start_port > 0 ? var.post_start_port : var.ports[0].container_port
                  }
                }
              }
            }
          }
          dynamic "security_context" {
            for_each = var.security_context_container_enabled ? [1] : []
            content {
              capabilities {
                add  = var.security_context_container_capabilities_add
                drop = var.security_context_container_capabilities_drop
              }
            }
          }
          dynamic "resources" {
            for_each = length(var.resources_limits_cpu) > 0 || length(var.resources_limits_memory) > 0 || length(var.resources_requests_cpu) > 0 || length(var.resources_requests_memory) > 0 ? [1] : []
            content {
              limits = length(var.resources_limits_cpu) > 0 && length(var.resources_limits_memory) > 0 ? {
                cpu    = var.resources_limits_cpu
                memory = var.resources_limits_memory
                } : length(var.resources_limits_cpu) > 0 ? {
                cpu = var.resources_limits_cpu
                } : length(var.resources_limits_memory) > 0 ? {
                memory = var.resources_limits_memory
              } : {}
              requests = length(var.resources_requests_cpu) > 0 && length(var.resources_requests_memory) > 0 ? {
                cpu    = var.resources_requests_cpu
                memory = var.resources_requests_memory
                } : length(var.resources_limits_cpu) > 0 ? {
                cpu = var.resources_requests_cpu
                } : length(var.resources_requests_memory) > 0 ? {
                memory = var.resources_requests_memory
              } : {}
            }
          }
          dynamic "port" {
            for_each = var.ports
            content {
              name           = port.value["name"]
              protocol       = port.value["protocol"]
              container_port = port.value["container_port"]
            }
          }
          dynamic "env" {
            for_each = [for env_var in var.env_secret : {
              name   = env_var.name
              secret = env_var.secret
              key    = env_var.key
            }]
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
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          dynamic "readiness_probe" {
            for_each = var.readiness_probe_enabled ? [1] : []
            content {
              initial_delay_seconds = var.startup_probe_enabled ? null : var.readiness_probe_initial_delay
              period_seconds        = var.readiness_probe_period
              timeout_seconds       = var.readiness_probe_timeout
              success_threshold     = var.readiness_probe_success
              failure_threshold     = var.readiness_probe_failure
              dynamic "exec" {
                for_each = var.readiness_probe_type == "exec" ? [1] : []
                content {
                  command = var.readiness_probe_command
                }
              }
              dynamic "http_get" {
                for_each = var.readiness_probe_type == "http_get" ? [1] : []
                content {
                  host = var.readiness_probe_host
                  dynamic "http_header" {
                    for_each = length(var.readiness_probe_http_header) > 0 ? var.readiness_probe_http_header : []
                    content {
                      name  = http_header.value["name"]
                      value = http_header.value["value"]
                    }
                  }
                  path   = var.readiness_probe_path
                  port   = var.readiness_probe_port > 0 ? var.readiness_probe_port : lookup({ for port in var.ports : lower(port.name) => port.container_port }, lower(var.readiness_probe_scheme), var.ports[0].container_port)
                  scheme = var.readiness_probe_scheme
                }
              }
              dynamic "tcp_socket" {
                for_each = var.readiness_probe_type == "tcp_socket" ? [1] : []
                content {
                  port = var.readiness_probe_port > 0 ? var.readiness_probe_port : var.ports[0].container_port
                }
              }
            }
          }
          dynamic "liveness_probe" {
            for_each = var.liveness_probe_enabled ? [1] : []
            content {
              initial_delay_seconds = var.startup_probe_enabled ? null : var.liveness_probe_initial_delay
              period_seconds        = var.liveness_probe_period
              timeout_seconds       = var.liveness_probe_timeout
              success_threshold     = var.liveness_probe_success
              failure_threshold     = var.liveness_probe_failure
              dynamic "exec" {
                for_each = var.liveness_probe_type == "exec" ? [1] : []
                content {
                  command = var.liveness_probe_command
                }
              }
              dynamic "http_get" {
                for_each = var.liveness_probe_type == "http_get" ? [1] : []
                content {
                  host = var.liveness_probe_host
                  dynamic "http_header" {
                    for_each = length(var.liveness_probe_http_header) > 0 ? var.liveness_probe_http_header : []
                    content {
                      name  = http_header.value["name"]
                      value = http_header.value["value"]
                    }
                  }
                  path   = var.liveness_probe_path
                  port   = var.liveness_probe_port > 0 ? var.liveness_probe_port : lookup({ for port in var.ports : lower(port.name) => port.container_port }, lower(var.liveness_probe_scheme), var.ports[0].container_port)
                  scheme = var.liveness_probe_scheme
                }
              }
              dynamic "tcp_socket" {
                for_each = var.liveness_probe_type == "tcp_socket" ? [1] : []
                content {
                  port = var.liveness_probe_port > 0 ? var.liveness_probe_port : var.ports[0].container_port
                }
              }
            }
          }
          dynamic "startup_probe" {
            for_each = var.startup_probe_enabled ? [1] : []
            content {
              initial_delay_seconds = var.startup_probe_initial_delay
              period_seconds        = var.startup_probe_period
              timeout_seconds       = var.startup_probe_timeout
              success_threshold     = var.startup_probe_success
              failure_threshold     = var.startup_probe_failure
              dynamic "exec" {
                for_each = var.startup_probe_type == "exec" ? [1] : []
                content {
                  command = var.startup_probe_command
                }
              }
              dynamic "http_get" {
                for_each = var.startup_probe_type == "http_get" ? [1] : []
                content {
                  host = var.startup_probe_host
                  dynamic "http_header" {
                    for_each = length(var.startup_probe_http_header) > 0 ? var.startup_probe_http_header : []
                    content {
                      name  = http_header.value["name"]
                      value = http_header.value["value"]
                    }
                  }
                  path   = var.startup_probe_path
                  port   = var.startup_probe_port > 0 ? var.startup_probe_port : lookup({ for port in var.ports : lower(port.name) => port.container_port }, lower(var.startup_probe_scheme), var.ports[0].container_port)
                  scheme = var.startup_probe_scheme
                }
              }
              dynamic "tcp_socket" {
                for_each = var.startup_probe_type == "tcp_socket" ? [1] : []
                content {
                  port = var.startup_probe_port > 0 ? var.startup_probe_port : var.ports[0].container_port
                }
              }
            }
          }
          dynamic "volume_mount" {
            for_each = flatten([for volume in var.volumes : [
              for vol_mount in volume.mounts : {
                name       = volume.name
                mount_path = vol_mount.mount_path
                sub_path   = lookup(vol_mount, "sub_path", "")
                read_only  = lookup(vol_mount, "read_only", false)
              }]
            ])
            content {
              name       = volume_mount.value["name"]
              mount_path = volume_mount.value["mount_path"]
              sub_path   = volume_mount.value["sub_path"]
              read_only  = volume_mount.value["read_only"]
            }
          }
          dynamic "volume_mount" {
            for_each = length(var.custom_certificate_authority) > 0 ? [for vol_mount in [
              { "name" = "etc-ssl-certs", "path" = "/etc/ssl/certs", "ro" = "true" },
              { "name" = "etc-ssl-private", "path" = "/etc/ssl/private", "ro" = "true" },
              { "name" = "custom-ca-certificates", "path" = "/usr/local/share/ca-certificates", "ro" = "true" }] : {
              name       = vol_mount.name
              mount_path = vol_mount.path
              read_only  = vol_mount.ro
            }] : []
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
            run_as_user  = var.security_context_uid
            run_as_group = var.security_context_gid
            fs_group     = var.security_context_fsgroup
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
                dynamic "items" {
                  for_each = [for mount in volume.value.mounts : mount if anytrue([
                    contains(keys(mount), "sub_path")
                  ])]
                  content {
                    key  = items.value.sub_path
                    mode = lookup(items.value, "mode", null)
                    path = items.value.sub_path
                  }
                }
              }
            }
            dynamic "secret" {
              for_each = volume.value["type"] == "secret" ? [1] : []
              content {
                secret_name  = volume.value["object_name"]
                default_mode = lookup(volume.value, "default_mode", "0644")
                optional     = lookup(volume.value, "optional", "false")
                dynamic "items" {
                  for_each = [for mount in volume.value.mounts : mount if anytrue([
                    contains(keys(mount), "sub_path")
                  ])]
                  content {
                    key  = items.value.sub_path
                    mode = lookup(items.value, "mode", null)
                    path = items.value.sub_path
                  }
                }
              }
            }
          }
        }
        dynamic "volume" {
          for_each = length(var.custom_certificate_authority) > 0 ? [for vol_name in [
            "etc-ssl-certs", "etc-ssl-private"] : {
            name = vol_name
          }] : []
          content {
            name = volume.value["name"]
            empty_dir {
              medium = "Memory"
            }
          }
        }
        dynamic "volume" {
          for_each = length(var.custom_certificate_authority) > 0 ? [1] : []
          content {
            name = "custom-ca-certificates"
            projected {
              default_mode = "0444"
              dynamic "sources" {
                for_each = var.custom_certificate_authority
                content {
                  secret {
                    name = sources.value
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "deployment" {
  count = length(var.ports) > 0 ? 1 : 0
  metadata {
    namespace   = var.namespace
    name        = var.object_prefix
    labels      = local.common_labels
    annotations = var.service_annotations
  }
  spec {
    selector                = local.selector_labels
    session_affinity        = var.service_session_affinity
    type                    = var.service_type
    external_traffic_policy = contains(["LoadBalancer", "NodePort"], var.service_type) ? var.service_traffic_policy : null
    load_balancer_ip        = length(var.service_loadbalancer_ip) > 0 ? var.service_loadbalancer_ip : null
    dynamic "port" {
      for_each = [for port in var.ports : {
        name           = port.name
        protocol       = port.protocol
        container_port = port.container_port
        service_port   = port.service_port
      } if contains(keys(port), "service_port")]
      content {
        name        = port.value["name"]
        protocol    = port.value["protocol"]
        target_port = port.value["container_port"]
        port        = port.value["service_port"]
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "deployment" {
  count = length(var.network_policy_ingress) + length(var.network_policy_egress) > 0 ? 1 : 0
  metadata {
    namespace   = var.namespace
    name        = var.object_prefix
    labels      = local.common_labels
    annotations = var.service_annotations
  }
  spec {
    pod_selector {
      match_labels = local.selector_labels
    }
    dynamic "ingress" {
      for_each = var.network_policy_ingress
      content {
        dynamic "ports" {
          for_each = ingress.value.ports
          content {
            port     = ports.value.port
            protocol = ports.value.protocol
          }
        }
        dynamic "from" {
          for_each = lookup(ingress.value, "selectors", [])
          content {
            dynamic "namespace_selector" {
              for_each = contains(keys(from.value), "namespace") ? [1] : []
              content {
                match_labels = contains(keys(from.value.namespace), "match_expressions") ? null : lookup(from.value.namespace, "match_labels", from.value.namespace)
              }
            }
            dynamic "pod_selector" {
              for_each = contains(keys(from.value), "pod") ? [1] : []
              content {
                match_labels = contains(keys(from.value.pod), "match_expressions") ? null : lookup(from.value.pod, "match_labels", from.value.pod)
              }
            }
            dynamic "ip_block" {
              for_each = contains(keys(from.value), "ip") ? [1] : []
              content {
                cidr   = can(keys(from.value.ip)) ? tostring(from.value.ip.cidr) : tostring(from.value.ip)
                except = can(keys(from.value.ip)) ? lookup(from.value.ip, "except", null) : null
              }
            }
          }
        }
      }
    }
    dynamic "egress" {
      for_each = var.network_policy_egress
      content {
        dynamic "ports" {
          for_each = egress.value.ports
          content {
            port     = ports.value.port
            protocol = ports.value.protocol
          }
        }
        dynamic "to" {
          for_each = lookup(egress.value, "selectors", [])
          content {
            dynamic "namespace_selector" {
              for_each = contains(keys(to.value), "namespace") ? [1] : []
              content {
                match_labels = contains(keys(to.value.namespace), "match_expressions") ? null : lookup(to.value.namespace, "match_labels", to.value.namespace)
              }
            }
            dynamic "pod_selector" {
              for_each = contains(keys(to.value), "pod") ? [1] : []
              content {
                match_labels = contains(keys(to.value.pod), "match_expressions") ? null : lookup(to.value.pod, "match_labels", to.value.pod)
              }
            }
            dynamic "ip_block" {
              for_each = contains(keys(to.value), "ip") ? [1] : []
              content {
                cidr   = can(keys(to.value.ip)) ? tostring(to.value.ip.cidr) : tostring(to.value.ip)
                except = can(keys(to.value.ip)) ? lookup(to.value.ip, "except", null) : null
              }
            }
          }
        }
      }
    }
    policy_types = var.network_policy_type
  }
}
