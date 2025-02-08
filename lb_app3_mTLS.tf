resource "oci_load_balancer_backend_set" "bkendset_hs3" {
  name             = "bkendset_hs3"
  load_balancer_id = oci_load_balancer.lb.id
  policy           = "ROUND_ROBIN"
  health_checker {
    port                = 22
    protocol            = "TCP"
    interval_ms = 10000
    timeout_in_millis = 5000
  }
}

resource "oci_load_balancer_backend" "bkend_hs3" {
    count               = var.backend_hs3_count
    backendset_name = oci_load_balancer_backend_set.bkendset_hs3.name
    ip_address = oci_core_instance.lb_bkend_hs3[count.index].private_ip
    load_balancer_id = oci_load_balancer.lb.id
    port = 8080
    backup = false
}


resource "oci_load_balancer_certificate" "lb_cert_hs3" {
  load_balancer_id   = oci_load_balancer.lb.id
  ca_certificate     = tls_self_signed_cert.root_ca_server.cert_pem

  certificate_name   = "self_cert_hs3_listener"

  private_key        = tls_private_key.server_hs3.private_key_pem
  public_certificate = tls_locally_signed_cert.server_hs3.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_hostname" "hs3" {
  hostname         = "hs3.free.com"
  load_balancer_id = oci_load_balancer.lb.id
  name             = "hs3"
}

resource "oci_load_balancer_certificate" "client_ca_bundle_hs3" {
  load_balancer_id   = oci_load_balancer.lb.id
  ca_certificate     = tls_self_signed_cert.root_ca_client.cert_pem

  certificate_name   = "client_ca_bundle_of_hs3_clients"
  private_key        = tls_private_key.client_hs3.private_key_pem
  public_certificate = tls_locally_signed_cert.client_hs3.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

# resource "oci_load_balancer_rule_set" "fwd_client_certs_to_backend" {
#   name              = "fwd_client_certs_to_backend_hs3"
#   load_balancer_id  = oci_load_balancer.lb.id

#   items {
#     action      = "ADD_HTTP_REQUEST_HEADER"
#     description = "Ruleset to add client certificate as request header"
#     header      = "x-client-cert"
#     value       = "{oci_lb_client_cert}"
#   }

#   lifecycle {
#     ignore_changes = [items]
#   }
# }

resource "oci_load_balancer_listener" "lb_listener_hs3_mtls" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = "hs3_mtls"
  default_backend_set_name = oci_load_balancer_backend_set.bkendset_hs3.name
  port                     = 443
  protocol                 = "HTTP"
  hostname_names           = [oci_load_balancer_hostname.hs3.name]
  connection_configuration {
    idle_timeout_in_seconds = 300
  }

  # rule_set_names = [ oci_load_balancer_rule_set.fwd_client_certs_to_backend.name ]

  ssl_configuration {
    # LB listener's certificate
    certificate_name        = oci_load_balancer_certificate.lb_cert_hs3_with_client_bundle.certificate_name

    # mTLS configs below
    verify_peer_certificate = true 
    
    # client's CA bundle
    #trusted_certificate_authority_ids = [oci_load_balancer_certificate.client_ca_bundle_hs3.id]
    verify_depth            = "3"
  }
}


resource "oci_load_balancer_certificate" "lb_cert_hs3_with_client_bundle" {
  load_balancer_id   = oci_load_balancer.lb.id
  certificate_name   = "hs3_client_server_mtls_ca_bundle"

  # CA Bundle as per rules here https://serverfault.com/questions/476576/how-to-combine-various-certificates-into-single-pem
  ca_certificate     = join("", [tls_locally_signed_cert.intermediate_ca_server.cert_pem, tls_self_signed_cert.root_ca_server.cert_pem, 
                                 tls_locally_signed_cert.intermediate_ca_client.cert_pem, tls_self_signed_cert.root_ca_client.cert_pem])

  # public certficate abc of the server and server private_key for its cert abc
  public_certificate = tls_locally_signed_cert.server_hs3.cert_pem
  private_key        = tls_private_key.server_hs3.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

output "ca_bundle" {
  value = join("", [tls_locally_signed_cert.server_hs3.cert_pem, tls_locally_signed_cert.intermediate_ca_server.cert_pem, tls_self_signed_cert.root_ca_client.cert_pem])
}
