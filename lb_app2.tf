resource "oci_load_balancer_backend_set" "bkendset_hs2" {
  name             = "bkendset_hs2"
  load_balancer_id = oci_load_balancer.lb.id
  policy           = "ROUND_ROBIN"
  health_checker {
    port                = 22
    protocol            = "TCP"
    interval_ms = 10000
    timeout_in_millis = 5000
  }
}

resource "oci_load_balancer_backend" "bkend_hs2" {
    count               = var.backend_hs2_count
    backendset_name = oci_load_balancer_backend_set.bkendset_hs2.name
    ip_address = oci_core_instance.lb_bkend_hs2[count.index].private_ip
    load_balancer_id = oci_load_balancer.lb.id
    port = 8080
    backup = false
}


resource "oci_load_balancer_certificate" "lb_cert_hs2" {
  load_balancer_id   = oci_load_balancer.lb.id
  ca_certificate     = tls_self_signed_cert.ca.cert_pem

  certificate_name   = "self_cert_hs2"
  private_key        = tls_private_key.server_hs2.private_key_pem
  public_certificate = tls_locally_signed_cert.server_hs2.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_hostname" "hs2" {
  hostname         = "hs2.free.com"
  load_balancer_id = oci_load_balancer.lb.id
  name             = "hs2"
  depends_on = [ oci_load_balancer_hostname.hs1 ]
}

resource "oci_load_balancer_listener" "lb_listener_hs2" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = "hs2"
  default_backend_set_name = oci_load_balancer_backend_set.bkendset_hs2.name
  port                     = 443
  protocol                 = "HTTP"
  hostname_names           = [oci_load_balancer_hostname.hs2.name]
  connection_configuration {
    idle_timeout_in_seconds = 300
  }

  routing_policy_name = oci_load_balancer_load_balancer_routing_policy.goto_backend_of_hs1.name
  rule_set_names = [ oci_load_balancer_rule_set.redirect_rule.name ]
  
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_cert_hs2.certificate_name
    verify_peer_certificate = false # used for mTLS
    # server_order_preference = "ENABLED"
    verify_depth            = "1"
  }
}


resource oci_load_balancer_rule_set redirect_rule {
  load_balancer_id = oci_load_balancer.lb.id
  name             = "redirect_rule_hs2_to_hs1"
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/go_to_echo_rule_set"
      operator        = "EXACT_MATCH"
    }
    redirect_uri {
      host     = oci_load_balancer_hostname.hs1.hostname
      path     = "/echo"
      port     = "443"
      protocol = "https"
      query    = "?{query}"
    }
    response_code = "302"
  }
}

resource "oci_load_balancer_load_balancer_routing_policy" "goto_backend_of_hs1" {
  condition_language_version = "V1"
  load_balancer_id = oci_load_balancer.lb.id
  name = "goto_backend_of_hs1"
  rules { 
        actions {
            name = "FORWARD_TO_BACKENDSET"
            backend_set_name = oci_load_balancer_backend_set.bkendset_hs1.name
        }
        condition = "any(http.request.url.path sw '/routing_policy_demo', http.request.url.path sw '/routing_policy_demo/')"
        name = "goto_backend_of_hs1_rule"
   }  
   rules {
          actions {
             name= "FORWARD_TO_BACKENDSET"
             backend_set_name= oci_load_balancer_backend_set.bkendset_hs1.name
          }
          name = "mobile_user_rule"
          condition = "all(http.request.headers[(i 'user-agent')] eq (i 'mobile') )"
    }
}
