# Terraform Kubernetes Deployment

This terraform module deploys a deployment on kubernetes and adds a service.

## Usage

```
module "deployment" {
  source              = "ballj/deployment/kubernetes"
  version             = "~> 2.4"
  image_name          = "nginx"
  image_tag           = "latest"
  namespace           = "production"
  object_prefix       = "nginx"
  ports               = [
    {
      name           = "http"
      protocol       = "TCP"
      container_port = "8080"
      service_port   = "80"
    },
    {
      name           = "https"
      protocol       = "TCP"
      container_port = "8443"
      service_port   = "443"
    }
  ]
  volumes  = [{
    name         = "html"
    type         = "persistent_volume_claim"
    object_name  = "nginx"
    readonly     = false
    mounts = [{
      mount_path = "/usr/share/nginx/html"
    }]
  }]
  labels              = {
    "app.kubernetes.io/part-of" = "nginx"
  }
  env = {
    NGINX_HOST                  = "example.com",
    NGINX_ENTRYPOINT_QUIET_LOGS = 1
  }
  env_secret = [{
    name   = "USERNAME"
    secret = app-secret
    key    = "username"
  },
  {
    name   = "PASSWORD"
    secret = app-secret
    key    = "password"
  }]
  custom_certificate_authority = [ "my-ca" ]
}
```

## Variables

### Deployment Variables

| Variable                                       | Required | Default          | Description                                        |
| ---------------------------------------------- | -------- | ---------------- | -------------------------------------------------- |
| `namespace`                                    | Yes      | N/A              | Kubernetes namespace to deploy into                |
| `object_prefix`                                | Yes      | N/A              | Unique name to prefix all objects with             |
| `labels`                                       | No       | N/A              | Common labels to add to all objects - See example  |
| `image_name`                                   | Yes      | N/A              | Image to deploy as part of deployment              |
| `image_tag`                                    | Yes      | N/A              | Image tag to deploy                                |
| `timeout_create`                               | No       | `3m`             | Timeout for creating the deployment                |
| `timeout_update`                               | No       | `3m`             | Timeout for updating the deployment                |
| `timeout_delete`                               | No       | `10m`            | Timeout for deleting the deployment                |
| `resources_requests_cpu`                       | No       | `null`           | The minimum amount of compute resources required   |
| `resources_requests_memory`                    | No       | `null`           | The minimum amount of compute resources required   |
| `resources_limits_cpu`                         | No       | `null`           | The maximum amount of compute resources allowed    |
| `resources_limits_memory`                      | No       | `null`           | The maximum amount of compute resources allowed    |
| `ports`                                        | No       | `[]`             | List of ports to configure - see example           |
| `service_account_name`                         | No       | `""`             | Service account to attach to the pod               |
| `subdomain`                                    | No       | `""`             | Subdomain for the pod                              |
| `service_links`                                | No       | `false`          | Use service links, check kubernetes documentation  |
| `replicas`                                     | No       | `1`              | Amount of pods to deploy as part of deployment     |
| `pull_policy`                                  | No       | `IfNotPresent`   | Pull policy for the image                          |
| `annotations`                                  | No       | `{}`             | Annotations to add to the deployment               |
| `template_annotations`                         | No       | `{}`             | Annotations to add to the template (recreate pods) |
| `update_strategy`                              | No       | `RollingUpdate`  | Strategy to use, `Recreate` or `RollingUpdate`     |
| `update_max_surge`                             | No       | `1`              | Number of pods that can be scheduled above desired |
| `update_max_unavailable`                       | No       | `1`              | Number of pods that can be unavailable             |
| `min_ready_seconds`                            | No       | `1`              | Minimum time to consider pods ready                |
| `max_ready_seconds`                            | No       | `600`            | Maximum time for pod to be ready before failure    |
| `revision_history`                             | No       | `4`              | Number of ReplicaSets to retain                    |
| `volumes`                                      | No       | `[]`             | List containing volume to mount - see example      |
| `security_context_enabled`                     | No       | `true`           | Enable security context at pod level               |
| `security_context_uid`                         | No       | `1000`           | User to run pod as                                 |
| `security_context_gid`                         | No       | `1000`           | Group to run pod as                                |
| `security_context_fsgroup`                     | No       | `1000`           | fsGroup to run pod as                              |
| `security_context_container_enabled`           | No       | `false`          | Enable security context at container level         |
| `security_context_container_capabilities_add`  | No       | `null`           | Added capabilities as                              |
| `security_context_container_capabilities_drop` | No       | `null`           | Removed capabilities as                            |
| `custom_certificate_authority`                 | No       | `[]`             | Certificate authorities to add to image            |
| `connectivity_check`                           | No       | `[]`             | Hostnames to check connectivity to                 |
| `command`                                      | No       | `[]`             | List of commands to run as entrypoint              |
| `arguments`                                    | No       | `[]`             | Arguments to the entrypoint                        |
| `env`                                          | No       | `{}`             | Environment variables to add                       |
| `env_secret`                                   | No       | `[]`             | Environmentvariables to add from secrets           |
| `readiness_probe_enabled`                      | No       | `true`           | Enable the readiness probe                         |
| `readiness_probe_initial_delay`                | No       | `30`             | Initial delay of the probe in seconds              |
| `readiness_probe_period`                       | No       | `10`             | Period of the probe in seconds                     |
| `readiness_probe_timeout`                      | No       | `1`              | Timeout of the probe in seconds                    |
| `readiness_probe_success`                      | No       | `1`              | Minimum consecutive successes for the probe        |
| `readiness_probe_failure`                      | No       | `3`              | Minimum consecutive failures for the probe         |
| `readiness_probe_type`                         | No       | `tcp_socket`     | Type of probe `tcp_socket`/`http_get`/`exec`       |
| `readiness_probe_command`                      | No       | `[]`             | Command for `exec` probe                           |
| `readiness_probe_host`                         | No       | `""`             | Hostname/IP for connection - recommend host_header |
| `readiness_probe_scheme`                       | No       | `HTTP`           | `HTTP"` or `"HTTPS"`                               |
| `readiness_probe_path`                         | No       | `/`              | Path for the http_get probe                        |
| `readiness_probe_http_header`                  | No       | `[]`             | HTTP headers                                       |
| `liveness_probe_enabled`                       | No       | `true`           | Enable the liveness probe                          |
| `liveness_probe_initial_delay`                 | No       | `30`             | Initial delay of the probe in seconds              |
| `liveness_probe_period`                        | No       | `10`             | Period of the probe in seconds                     |
| `liveness_probe_timeout`                       | No       | `1`              | Timeout of the probe in seconds                    |
| `liveness_probe_success`                       | No       | `1`              | Minimum consecutive successes for the probe        |
| `liveness_probe_failure`                       | No       | `3`              | Minimum consecutive failures for the probe         |
| `liveness_probe_type`                          | No       | `tcp_socket`     | Type of probe `tcp_socket`/`http_get`/`exec`       |
| `liveness_probe_command`                       | No       | `[]`             | Command for `exec` probe                           |
| `liveness_probe_host`                          | No       | `""`             | Hostname/IP for connection - recommend host_header |
| `liveness_probe_scheme`                        | No       | `HTTP`           | `HTTP"` or `"HTTPS"`                               |
| `liveness_probe_path`                          | No       | `/`              | Path for the http_get probe                        |
| `liveness_probe_http_header`                   | No       | `[]`             | HTTP headers                                       |
| `startup_probe_enabled`                        | No       | `true`           | Enable the startup probe                           |
| `startup_probe_initial_delay`                  | No       | `10`             | Initial delay of the probe in seconds              |
| `startup_probe_period`                         | No       | `1`              | Period of the probe in seconds                     |
| `startup_probe_timeout`                        | No       | `1`              | Timeout of the probe in seconds                    |
| `startup_probe_success`                        | No       | `1`              | Minimum consecutive successes for the probe        |
| `startup_probe_failure`                        | No       | `90`             | Minimum consecutive failures for the probe         |
| `startup_probe_type`                           | No       | `tcp_socket`     | Type of probe `tcp_socket`/`http_get`/`exec`       |
| `startup_probe_command`                        | No       | `[]`             | Command for `exec` probe                           |
| `startup_probe_host`                           | No       | `""`             | Hostname/IP for connection - recommend host_header |
| `startup_probe_scheme`                         | No       | `HTTP`           | `HTTP"` or `"HTTPS"`                               |
| `startup_probe_path`                           | No       | `/`              | Path for the http_get probe                        |
| `startup_probe_http_header`                    | No       | `[]`             | HTTP headers                                       |
| `post_start_type`                              | No       | `""`             | Type of probe `tcp_socket`/`http_get`/`exec`       |
| `post_start_command`                           | No       | `[]`             | Command for `exec` type                            |
| `post_start_host`                              | No       | `""`             | Hostname/IP for connection - recommend host_header |
| `post_start_scheme`                            | No       | `HTTP`           | `HTTP"` or `"HTTPS"`                               |
| `post_start_path`                              | No       | `/`              | Path for the http_get comand                       |
| `post_start_http_header`                       | No       | `[]`             | HTTP headers                                       |

### Init Containers

#### Volume Permissions

| Variable                                    | Required | Default          | Description                                        |
| ------------------------------------------- | -------- | -------          | -------------------------------------------------- |
| `init_volume_permissions_image_name`        | No       | `alpine`         | Image name of the init volume                      |
| `init_volume_permissions_extraargs`         | No       | `[]`             | Extra commands to run on the container             |
| `init_volume_permissions_image_tag`         | No       | N/A              | Tag of the init volume                             |
| `init_volume_permissions_image_pull_policy` | No       | N/A              | Pull policy for the init volume                    |

#### Custom Certificates

| Variable                                    | Required | Default          | Description                                        |
| ------------------------------------------- | -------- | -------          | -------------------------------------------------- |
| `init_customca_image_name`                  | No       | `alpine`         | Image name of the init volume                      |
| `init_customca_image_tag`                   | No       | N/A              | Tag of the init volume                             |
| `init_customca_image_pull_policy`           | No       | N/A              | Pull policy for the init volume                    |
| `init_customca_env_secret`                  | No       | N/A              | Secrets to add into the init container - eg proxy  |

#### Custom Certificates

| Variable                                    | Required | Default          | Description                                        |
| ------------------------------------------- | -------- | -------          | -------------------------------------------------- |
| `init_connectivity_image_name`              | No       | `alpine`         | Image name of the init volume                      |
| `init_connectivity_image_tag`               | No       | N/A              | Tag of the init volume                             |
| `init_customca_image_pull_policy`           | No       | N/A              | Pull policy for the init volume                    |
| `init_customca_env_secret`                  | No       | N/A              | Secrets to add into the init container - eg proxy  |

#### Custom User Init Container

Will be automatically enabled if `init_user_image_name` and `init_user_image_tag` are set.

| Variable                            | Required | Default        | Description                                        |
| ----------------------------------- | -------- | -------------- | -------------------------------------------------- |
| `init_user_image_name`              | Yes      | `""`           | Image name of the init volume                      |
| `init_user_image_tag`               | Yes      | `""`           | Tag of the init volume                             |
| `init_user_command`                 | Yes      | `[]`           | Command to run within the container                |
| `init_user_arguments`               | Yes      | `[]`           | Arguments to run within the container              |
| `init_user_image_pull_policy`       | No       | `IfNotPresent` | Pull policy for the init volume                    |
| `init_user_security_context_uid`    | No       | `1000`         | User to run container as                           |
| `init_user_security_context_gid`    | No       | `1000`         | Group to run container as                          |
| `init_user_env`                     | No       | `[]`           | Environment variables for init container           |
| `init_user_env_secret`              | No       | `[]`           | Secrets to add into the init container - eg proxy  |

### Service Variables

| Variable                                    | Required | Default          | Description                                        |
| ------------------------------------------- | -------- | ---------------- | -------------------------------------------------- |
| `service_type`                              | No       | `ClusterIP`      | Service type to deploy                             |
| `service_annotations`                       | No       | `{}`             | Annotations to add to service                      |
| `service_session_affinity`                  | No       | `None`           | Session persistence setting                        |
| `service_traffic_policy`                    | No       | `Local`          | External traffic policy - `Local` or `External`    |
| `service_loadbalancer_ip`                   | No       | `""`             | IP address to request from the loadbalancer        |
| `labels`                                    | No       | N/A              | Common labels to add to all objects - See example  |

### Port Variables

If `ports` is defined, a list of map is required with the variables.
See below for an example.

| Variable                                    | Required | Default          | Description                                        |
| ------------------------------------------- | -------- | ---------------- | -------------------------------------------------- |
| `name`                                      | Yes      | N/A              | Name of the port                                   |
| `protocol`                                  | Yes      | N/A              | Type of volume. See Supported volume types         |
| `container_port`                            | Yes      | N/A              | Port on the pod that application is listening on   |
| `service_port`                              | No       | N/A              | If specifed, port is created on the service        |

### Volume Variables

If `volumes` is defined, a list of map is required with the variables.
See below for an example.

| Variable                                    | Required | Default          | Description                                        |
| ------------------------------------------- | -------- | ---------------- | -------------------------------------------------- |
| `name`                                      | Yes      | N/A              | Name of the volume to create                       |
| `type`                                      | Yes      | N/A              | Type of volume. See Supported volume types         |
| `object_name`                               | No       | N/A              | Name of object (pvc, secret, configmap)            |
| `readonly`                                  | No       | `false`          | PVC readonly flag                                  |
| `medium`                                    | No       | `""`             | Medium type for empty_dir                          |
| `default_mode`                              | No       | `0644`           | Default mode for config_map/secret                 |
| `optional`                                  | No       | `false`          | If config_map/secret needs to be present           |
| `size_limit`                                | No       | `0`              | Size limit for empty_dir                           |
| `mounts`                                    | Yes      | N/A              | List of mounts                                     |
| `mounts.mount_path`                         | Yes      | N/A              | Mount path in the container                        |
| `mounts.sub_path`                           | No       | N/A              | Mount sub_path in the container                    |
| `mounts.read_only`                          | No       | `false`          | Readonly flag for volume mount                     |
| `mounts.user`                               | No       | N/A              | Sets user for the volume (chown)                   |
| `mounts.group`                              | No       | N/A              | Sets group for the volume (chgrp)                  |
| `mounts.mode`                               | No       | N/A              | Sets permissions for the volume (chmod)            |

### Network Policy Variables

| Variable                                    | Required | Default                 | Description                                 |
| ------------------------------------------- | -------- | ----------------------- | ------------------------------------------- |
| `network_policy_type`                       | No       | `["Ingress", "Egress"]` | Direction of network policy                 |
| `network_policy_ingress`                    | No       | `[]`                    | Ingress policy to apply to deployment       |
| `network_policy_egress`                     | No       | `[]`                    | Egress policy to apply to deployment        |

## Persistence

Persistance is achieved by mounting PVCs into the container. This is achieve by
the following variables:

```bash
volumes   = [
  {
    name         = "html"
    type         = "persistent_volume_claim"
    object_name  = "nginx"
    mounts = [{ # This will mount all objects of persistent_volume_claim
      mount_path = "/usr/share/nginx"
    }]
  },
  {
    name         = "config"
    type         = "config_map"
    object_name  = "nginx-config"
    mounts = [
      { # This will mount only the nginx.conf file
        mount_path = "/etc/nginx.conf"
        sub_path   = "nginx.conf"
        read_only  = true
      },
      { # This will mount only the extra.conf file
        mount_path = "/etc/nginx"
        sub_path   = "extra.conf"
        read_only  = true
      },
      { # This will mount the config_map key original.conf at mount_path
        mount_path = "/etc/nginx/rename.conf"
        sub_path   = "original.conf"
        mode       = "0400"
      }
    ]
  },
  {
    name         = "logs"
    type         = "persistent_volume_claim"
    object_name  = "nginx-logs"
    readonly     = false
    mounts = [{ mount_path = "/var/logs" }]
  }
]
```

### Supported Volume Types

The following volume types are supported
- persistent_volume_claim
- empty_dir
- config_map
- secret

## Custom certificates

A list of secrets can be added to specify custom CAs to be added into the
container at `/etc/ssl`. This is accomplished using a init container running
`update_certificates`

Certs are loaded by adding the cert to a standard secret and specifying the
secret name in the variable:

```bash
custom_certificate_authority = [ "my-ca", "my-ca-2" ]
```

## Connectivity Check

Pass a list of hostnames to check and the service will wait for these to be
available before coming up.

```bash
connectivity_check = [
  {
    name     = "google"
    hostname = "www.google.com"
    port     = 443
    timeout  = 30
  }
]
```

## Network Policy

Network policy can be used to restrict network access to and from pods.
The default behaviour is to use both ingress and egress as soon as a single
policy is set. This can be controlled with `network_policy_type`.

Some of the fields are multifunctional:
- selectors.ip can be either a map or a string:
  - if its a string, its considered a CIDR.
  - if its a map, it allows cidr and except (similar to Terraform docs)
- selectors.pod and selectors.namespace can be a map of labels, or a map containing
  a match_labels variable (match_expressions not implemented yet)

Basic Policy:
```bash
  network_policy_ingress = [
    {
      ports = [
        {
          port     = "80"
          protocol = "TCP"
        }
      ]
      selectors = [
        {
          pod = {
            match_labels = { "app.kubernetes.io/part-of" = "nw-policy" }
          }
        }
      ]
    }
```

Advanced policy:
```bash
  network_policy_ingress = [
    {
      ports = [
        {
          port     = "80"
          protocol = "TCP"
        },
        {
          port     = "443"
          protocol = "TCP"
        }
      ]
      selectors = [
        {
          pod = {}
        },
        {
          ip = {
            cidr = "10.0.0.0/8"
          }
        },
        {
          ip = "192.168.1.0/24"
        },
      ]
    }
  ]
  network_policy_egress = [
    {
      ports = [
        {
          port     = "80"
          protocol = "TCP"
        }
      ]
      selectors = [{
        pod = { "app.kubernetes.io/part-of" = "nw-policy" }
      }]
    },
    {
      ports = [
        {
          port     = "53"
          protocol = "TCP"
        },
        {
          port     = "53"
          protocol = "UDP"
        }
      ]
      selectors = [{
        pod       = { "app.kubernetes.io/part-of" = "nw-policy" }
        namespace = { "kubernetes.io/metadata.name" = "apps" }
      }]
    }
  ]
  network_policy_type = ["Ingress", "Egress"]
```

## Notes

Variable `volumes` and `ports` does not have its type set as this requires [Optional Object Type Attributes](https://www.terraform.io/docs/language/expressions/type-constraints.html#experimental-optional-object-type-attributes)
to work correctly. This feature is currently experimental and so it not used at the moment.

## Upgrades

### v2.0.0

Change to v1 resource naming. This requires old resources be manually deleted
unless the object_prefix is changed. If this is not done Terraform will error
as the name already exists.

Changed service links to disabled by default. Change `service_links` = `true`
for old behaviour.

### v2.4.0

Changed the volume naming slightly. `permissions` has been renamed to `mode` to be
more consistent with the Kubernetes documentation. `permissions` will continue to
work until it is removed in the `v3.0.0` version.
