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
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_cert_hs2.certificate_name
    verify_peer_certificate = false # used for mTLS
    # server_order_preference = "ENABLED"
    verify_depth            = "1"
  }
}