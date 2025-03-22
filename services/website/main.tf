resource "digitalocean_app" "lemisieur-com-01" {
  project_id = "2355d858-d893-448f-8c7c-95741182426e"

  spec {
    name   = "lemisieur-com-01"
    region = "tor"

    dynamic "domain" {
      for_each = local.domains
      content {
        name = domain.value
      }
    }

    dynamic "env" {
      for_each = local.env_vars
      content {
        scope = env.value.scope
        key   = env.key
        value = env.value.value
      }
    }

    dynamic "alert" {
      for_each = local.alert_vars
      content {
        rule     = alert.key
        disabled = alert.value.disabled
      }
    }

    ingress {
      rule {
        component {
          name                 = "littlelink-server"
          preserve_path_prefix = false
        }
        match {
          path {
            prefix = "/"
          }
        }
      }
    }

    service {
      name               = "littlelink-server"
      instance_size_slug = "apps-s-1vcpu-0.5gb"
      instance_count     = 1

      http_port = 3000

      image {
        registry_type = "GHCR"
        registry      = "techno-tim"
        repository    = "littlelink-server"
        digest        = "sha256:9b7a42bb370fb0c9fd1cc55627c6d08535d7c2aa75436b2feb9d25e44ec0e504"
      }
    }
  }
}
