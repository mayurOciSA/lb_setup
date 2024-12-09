resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem
  subject {
      common_name  = "example-ca"
      organization = "Example CA"
    }

  validity_period_hours = 24 * 5
  is_ca_certificate     = true
  allowed_uses = [
     "key_encipherment", "digital_signature", "cert_signing", 
     "server_auth", "client_auth", "code_signing", "email_protection", 
     "ipsec_end_system", "ipsec_tunnel", "ipsec_user", "timestamping",
  ]
}

resource "tls_private_key" "server_hs1" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_hs1" {
  private_key_pem = tls_private_key.server_hs1.private_key_pem
  subject {
      common_name  = "example.com"
      organization = "Example"
    }
}

resource "tls_locally_signed_cert" "server_hs1" {
  cert_request_pem     = tls_cert_request.server_hs1.cert_request_pem
  ca_private_key_pem   = tls_private_key.ca.private_key_pem
  ca_cert_pem          = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 24 * 3
  is_ca_certificate    = false
  allowed_uses = [
    "key_encipherment", "digital_signature", "server_auth", "client_auth",
    "code_signing", "email_protection", "ipsec_end_system", 
    "ipsec_tunnel", "ipsec_user", "timestamping",
  ]
}

resource "tls_private_key" "server_hs2" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_hs2" {
  private_key_pem = tls_private_key.server_hs2.private_key_pem
  subject {
      common_name  = "example.com"
      organization = "Example"
    }
}

resource "tls_locally_signed_cert" "server_hs2" {
  cert_request_pem     = tls_cert_request.server_hs2.cert_request_pem
  ca_private_key_pem   = tls_private_key.ca.private_key_pem
  ca_cert_pem          = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 24 * 3
  is_ca_certificate    = false
  allowed_uses = [
    "key_encipherment", "digital_signature", "server_auth", "client_auth",
    "code_signing", "email_protection", "ipsec_end_system", 
    "ipsec_tunnel", "ipsec_user", "timestamping",
  ]
}

# resource "local_file" "certificate" {

#   content  = jsonencode({
#     server_hs1_certificate_pem    = tls_locally_signed_cert.server_hs1.cert_pem
#     server_hs1_private_key_pem     = tls_private_key.server_hs1.private_key_pem

#     server_hs2_certificate_pem    = tls_locally_signed_cert.server_hs2.cert_pem
#     server_hs2_private_key_pem     = tls_private_key.server_hs2.private_key_pem

#     ca_certificate_pem  = tls_self_signed_cert.ca.cert_pem
#     ca_private_key_pem  = tls_private_key.ca.private_key_pem
#   })
#   filename = "${path.module}/certsdir/certificate.json"
# }

resource "local_file" "ca_certificate_pem" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "${path.module}/certsdir/cert_ca.pem"
}

resource "null_resource" "ca_convert_cert_pem_to_text" {
  depends_on = [local_file.ca_certificate_pem]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/cert_ca.pem -text -noout > ${path.module}/certsdir/cert_ca.txt"
  }
}

resource "local_file" "server_hs1_certificate_pem" {
  content  = tls_locally_signed_cert.server_hs1.cert_pem
  filename = "${path.module}/certsdir/cert_hs1.pem"
}

resource "null_resource" "server_hs1_convert_cert_pem_to_text" {
  depends_on = [local_file.server_hs1_certificate_pem]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/cert_hs1.pem -text -noout > ${path.module}/certsdir/cert_hs1.txt"
  }
}

resource "local_file" "server_hs2_certificate_pem" {
  content  = tls_locally_signed_cert.server_hs2.cert_pem
  filename = "${path.module}/certsdir/cert_hs2.pem"
}

resource "null_resource" "server_hs2_convert_cert_pem_to_text" {
  depends_on = [local_file.server_hs2_certificate_pem]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/cert_hs2.pem -text -noout > ${path.module}/certsdir/cert_hs2.txt"
  }
}


resource "null_resource" "cleanup" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/certsdir/*"
    when    = destroy
  }
}
