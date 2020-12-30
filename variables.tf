variable "object_prefix" {
  type        = string
  description = "Unique name to prefix all objects with"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for deployment"
}

variable "image_name" {
  type        = string
  description = "Docker image to use"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag to use"
}

variable "timeout_create" {
  type        = string
  description = "Timeout for creating the deployment"
  default     = "3m"
}

variable "timeout_update" {
  type        = string
  description = "Timeout for creating the deployment"
  default     = "2m"
}

variable "timeout_delete" {
  type        = string
  description = "Timeout for creating the deployment"
  default     = "10m"
}

variable "labels" {
  type        = map(string)
  description = "Labels to add"
  default     = {}
}

variable "ports" {
  type        = any
  description = "Ports to expose from container"
  default     = []
}

variable "replicas" {
  type        = number
  description = "Amount of pods to create"
  default     = 1
}

variable "pull_policy" {
  type        = string
  description = "Pull policy for the image"
  default     = "IfNotPresent"
}

variable "annotations" {
  type        = map(string)
  description = "Annotations to add to the deployment"
  default     = {}
}

variable "template_annotations" {
  type        = map(string)
  description = "Annotations to add to the template"
  default     = {}
}

variable "min_ready_seconds" {
  type        = number
  description = "Minimum number of seconds for which a newly created pod should be ready without any of its container crashing"
  default     = 1
}

variable "max_ready_seconds" {
  type        = number
  description = "The maximum time in seconds for a deployment to make progress before it is considered to be failed"
  default     = 600
}

variable "revision_history" {
  type        = number
  description = "The number of old ReplicaSets to retain"
  default     = 4
}

variable "update_strategy" {
  type        = string
  description = "The number of old ReplicaSets to retain"
  default     = "RollingUpdate"
}

variable "update_max_surge" {
  type        = string
  description = "Maximum number of pods that can be scheduled above desired"
  default     = "25%"
}

variable "update_max_unavailable" {
  type        = string
  description = "Maximum number of pods that can be unavailable during the update"
  default     = "25%"
}

variable "command" {
  type        = list(string)
  description = "Entrypoint array. Not executed within a shell"
  default     = []
}

variable "arguments" {
  type        = list(string)
  description = "Arguments to the entrypoint"
  default     = []
}

variable "volumes" {
  type        = any
  description = "Volume configuration"
  default     = []
}

variable "security_context_enabled" {
  type        = bool
  description = "Enable the security context"
  default     = true
}

variable "security_context_uid" {
  type        = number
  description = "Group to run container as"
  default     = 1000
}

variable "security_context_gid" {
  type        = number
  description = "User to run container as"
  default     = 1000
}

variable "custom_certificate_authority" {
  type        = list(string)
  description = "Certificate authorities to add to image"
  default     = []
}

variable "env" {
  type        = map(string)
  description = "Environment variables"
  default     = {}
}

variable "env_secret" {
  type = list(object({
    name   = string
    secret = string
    key    = string
  }))
  description = "Environment variables to pull from secrets"
  default     = []
}

variable "post_start_type" {
  type        = string
  description = "Post_start is called immediately after a container is created"
  default     = ""
}

variable "post_start_command" {
  type        = list(string)
  description = "Post_start command to execute"
  default     = []
}

variable "post_start_host" {
  type        = string
  description = "Host that the http_get will test"
  default     = ""
}

variable "post_start_port" {
  type        = number
  description = "Port that the post_start will test"
  default     = 0
}

variable "post_start_scheme" {
  type        = string
  description = "Scheme of the http_get request"
  default     = "HTTP"
}

variable "post_start_path" {
  type        = string
  description = "Path for the http_get request"
  default     = "/"
}

variable "post_start_http_header" {
  type        = list(string)
  description = "HTTP headers for the http_get request"
  default     = []
}

variable "readiness_probe_enabled" {
  type        = bool
  description = "Enable the readyness probe"
  default     = true
}

variable "readiness_probe_initial_delay" {
  type        = number
  description = "Initial delay of the probe in seconds"
  default     = 30
}

variable "readiness_probe_period" {
  type        = number
  description = "Period of the probe in seconds"
  default     = 10
}

variable "readiness_probe_timeout" {
  type        = number
  description = "Timeout of the probe in seconds"
  default     = 1
}

variable "readiness_probe_success" {
  type        = number
  description = "Minimum consecutive successes for the probe"
  default     = 1
}

variable "readiness_probe_failure" {
  type        = number
  description = "Minimum consecutive failures for the probe"
  default     = 2
}

variable "readiness_probe_type" {
  type        = string
  description = "Type of probe to deploy"
  default     = "tcp_socket"
}

variable "readiness_probe_command" {
  type        = list(string)
  description = "Command for the probe to use"
  default     = []
}

variable "readiness_probe_host" {
  type        = string
  description = "Host that the probe will test"
  default     = ""
}

variable "readiness_probe_port" {
  type        = number
  description = "Port that the probe will test"
  default     = 0
}

variable "readiness_probe_scheme" {
  type        = string
  description = "Scheme of the probe http_get probe"
  default     = "HTTP"
}

variable "readiness_probe_path" {
  type        = string
  description = "Path for the http_get probe"
  default     = "/"
}

variable "readiness_probe_http_header" {
  type        = list(string)
  description = "HTTP headers for the http_get probe"
  default     = []
}

variable "liveness_probe_enabled" {
  description = "Enable the readyness probe"
  default     = true
}

variable "liveness_probe_initial_delay" {
  type        = number
  description = "Initial delay of the probe in seconds"
  default     = 30
}

variable "liveness_probe_period" {
  type        = number
  description = "Period of the probe in seconds"
  default     = 10
}

variable "liveness_probe_timeout" {
  type        = number
  description = "Timeout of the probe in seconds"
  default     = 1
}

variable "liveness_probe_success" {
  type        = number
  description = "Minimum consecutive successes for the probe"
  default     = 1
}

variable "liveness_probe_failure" {
  type        = number
  description = "Minimum consecutive failures for the probe"
  default     = 3
}

variable "liveness_probe_type" {
  type        = string
  description = "Type of probe to deploy"
  default     = "tcp_socket"
}

variable "liveness_probe_command" {
  type        = list(string)
  description = "Command for the probe to use"
  default     = []
}

variable "liveness_probe_host" {
  type        = string
  description = "Host that the probe will test"
  default     = ""
}

variable "liveness_probe_port" {
  type        = number
  description = "Port that the probe will test"
  default     = 0
}

variable "liveness_probe_scheme" {
  type        = string
  description = "Scheme of the probe http_get probe"
  default     = "HTTP"
}

variable "liveness_probe_path" {
  type        = string
  description = "Path for the http_get probe"
  default     = "/"
}

variable "liveness_probe_http_header" {
  type        = list(string)
  description = "HTTP headers for the http_get probe"
  default     = []
}

variable "startup_probe_enabled" {
  description = "Enable the readyness probe"
  default     = true
}

variable "startup_probe_initial_delay" {
  type        = number
  description = "Initial delay of the probe in seconds"
  default     = 10
}

variable "startup_probe_period" {
  type        = number
  description = "Period of the probe in seconds"
  default     = 1
}

variable "startup_probe_timeout" {
  type        = number
  description = "Timeout of the probe in seconds"
  default     = 1
}

variable "startup_probe_success" {
  type        = number
  description = "Minimum consecutive successes for the probe"
  default     = 1
}

variable "startup_probe_failure" {
  type        = number
  description = "Minimum consecutive failures for the probe"
  default     = 90
}

variable "startup_probe_type" {
  type        = string
  description = "Type of probe to deploy"
  default     = "tcp_socket"
}

variable "startup_probe_command" {
  type        = list(string)
  description = "Command for the probe to use"
  default     = []
}

variable "startup_probe_host" {
  type        = string
  description = "Host that the probe will test"
  default     = ""
}

variable "startup_probe_port" {
  type        = number
  description = "Port that the probe will test"
  default     = 0
}

variable "startup_probe_scheme" {
  type        = string
  description = "Scheme of the probe http_get probe"
  default     = "HTTP"
}

variable "startup_probe_path" {
  type        = string
  description = "Path for the http_get probe"
  default     = "/"
}

variable "startup_probe_http_header" {
  type        = list(string)
  description = "HTTP headers for the http_get probe"
  default     = []
}

variable "service_session_affinity" {
  type        = string
  description = "Used to maintain session affinity"
  default     = "None"
}

variable "service_type" {
  type        = string
  description = "Service type"
  default     = "ClusterIP"
}

variable "service_loadbalancer_ip" {
  type        = string
  description = "Default ip address for the loadbalancer"
  default     = ""
}

variable "service_annotations" {
  type        = map(string)
  description = "Annotations to add to the service"
  default     = {}
}

variable "service_traffic_policy" {
  type        = string
  description = "Service external traffic policy"
  default     = "Local"
}

variable "init_volume_permissions_enabled" {
  description = "Container to set volume permissions on pod startup"
  default     = true
}

variable "init_volume_permissions_extraargs" {
  type        = list(string)
  description = "Extra commands to run on the volume init container"
  default     = []
}

variable "init_volume_permissions_image_name" {
  type        = string
  description = "Image to use for the init container"
  default     = "alpine"
}

variable "init_volume_permissions_image_tag" {
  type        = string
  description = "Tag to use for the init container"
  default     = "3.12.3"
}

variable "init_volume_permissions_image_pull_policy" {
  type        = string
  description = "Pull policy to use for the init container"
  default     = "IfNotPresent"
}

variable "init_customca_image_name" {
  type        = string
  description = "Tag to use for the init container"
  default     = "alpine"
}

variable "init_customca_image_tag" {
  type        = string
  description = "Tag to use for the init container"
  default     = "3.12.3"
}

variable "init_customca_image_pull_policy" {
  type        = string
  description = "Pull policy to use for the init container"
  default     = "IfNotPresent"
}

variable "init_customca_env_secret" {
  type = list(object({
    name   = string
    secret = string
    key    = string
  }))
  description = "Env secrets to use for the init container"
  default     = []
}
