# Root CA for Server side certificates

resource "tls_private_key" "root_ca_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "root_ca_server" {
  private_key_pem = tls_private_key.root_ca_server.private_key_pem
  subject {
      common_name  = "server-root-example-ca"
      organization = "Server Root Example CA"
    }

  validity_period_hours = 24 * 5
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# Intermediate CA for Server side certificates

resource "tls_private_key" "intermediate_ca_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "intermediate_ca_server" { 
  # Certificate Signing Request (CSR): Using the private key, you create a CSR. 
  # The CSR contains information about your organization and the domain name for which you're requesting the certificate
  private_key_pem = tls_private_key.intermediate_ca_server.private_key_pem
  subject {
      common_name  = "intermediate_ca_server example.com"
      organization = "intermediate_ca_server Example"
    }
}

resource "tls_locally_signed_cert" "intermediate_ca_server" {
  cert_request_pem     = tls_cert_request.intermediate_ca_server.cert_request_pem
  ca_private_key_pem   = tls_private_key.root_ca_server.private_key_pem
  ca_cert_pem          = tls_self_signed_cert.root_ca_server.cert_pem

  validity_period_hours = 24 * 3
  is_ca_certificate    = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# Create server-side certificate for hs1 listener
resource "tls_private_key" "server_hs1" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_hs1" { 
  # Certificate Signing Request (CSR): Using the private key, you create a CSR. 
  # The CSR contains information about your organization and the domain name for which you're requesting the certificate
  private_key_pem = tls_private_key.server_hs1.private_key_pem
  subject {
      # CN is the domain name for which you're requesting the certificate, and it has to match, as clients will check it, in TLS
      common_name  = "hs1.free.com"
      organization = "server_hs1 Example"
    }
}

resource "tls_locally_signed_cert" "server_hs1" {
  cert_request_pem     = tls_cert_request.server_hs1.cert_request_pem
  ca_private_key_pem   = tls_private_key.intermediate_ca_server.private_key_pem
  ca_cert_pem          = tls_locally_signed_cert.intermediate_ca_server.cert_pem
  validity_period_hours = 24 * 3
  is_ca_certificate    = false
  allowed_uses = [
   "digital_signature", "server_auth", "client_auth",
  ]
}

# Create server-side certificate for hs2 listener
resource "tls_private_key" "server_hs2" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_hs2" {
  private_key_pem = tls_private_key.server_hs2.private_key_pem
  subject {
      common_name  = "hs2.free.com"
      organization = "server_hs2 Example"
    }
}

resource "tls_locally_signed_cert" "server_hs2" {
  cert_request_pem     = tls_cert_request.server_hs2.cert_request_pem
  ca_private_key_pem   = tls_private_key.intermediate_ca_server.private_key_pem
  ca_cert_pem          = tls_locally_signed_cert.intermediate_ca_server.cert_pem
  validity_period_hours = 24 * 3
  is_ca_certificate    = false
  allowed_uses = [
    "digital_signature", "server_auth", "client_auth",
  ]
}

# Create server-side certificate for hs3 listener
resource "tls_private_key" "server_hs3" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_hs3" {
  private_key_pem = tls_private_key.server_hs3.private_key_pem
  subject {
      common_name  = "hs3.free.com"
      organization = "server_hs3 Example"
    }
}

resource "tls_locally_signed_cert" "server_hs3" {
  cert_request_pem     = tls_cert_request.server_hs3.cert_request_pem
  ca_private_key_pem   = tls_private_key.intermediate_ca_server.private_key_pem
  ca_cert_pem          = tls_locally_signed_cert.intermediate_ca_server.cert_pem
  validity_period_hours = 24 * 3
  is_ca_certificate    = false
  allowed_uses = [
    "digital_signature", "server_auth", "client_auth",
  ]
}

# Create local copies for server side certificates in local directory certsdir
resource "local_file" "root_ca_server" {
  content  = tls_self_signed_cert.root_ca_server.cert_pem
  filename = "${path.module}/certsdir/root_ca_server.pem"
}

resource "null_resource" "root_ca_server" {
  depends_on = [local_file.root_ca_server]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/root_ca_server.pem -text -noout > ${path.module}/certsdir/root_ca_server.txt"
  }
}

resource "local_file" "intermediate_ca_server" {
  content  = tls_locally_signed_cert.intermediate_ca_server.cert_pem
  filename = "${path.module}/certsdir/intermediate_ca_server.pem"
}

resource "null_resource" "intermediate_ca_server" {
  depends_on = [local_file.intermediate_ca_server]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/intermediate_ca_server.pem -text -noout > ${path.module}/certsdir/intermediate_ca_server.txt"
  }
}

resource "local_file" "server_hs1" {
  content  = tls_locally_signed_cert.server_hs1.cert_pem
  filename = "${path.module}/certsdir/server_hs1.pem"
}

resource "null_resource" "server_hs1" {
  depends_on = [local_file.server_hs1]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/server_hs1.pem -text -noout > ${path.module}/certsdir/server_hs1.txt"
  }
}

resource "local_file" "server_hs2" {
  content  = tls_locally_signed_cert.server_hs2.cert_pem
  filename = "${path.module}/certsdir/server_hs2.pem"
}

resource "null_resource" "server_hs2" {
  depends_on = [local_file.server_hs2]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/server_hs2.pem -text -noout > ${path.module}/certsdir/server_hs2.txt"
  }
}

resource "local_file" "server_hs3" {
  content  = tls_locally_signed_cert.server_hs3.cert_pem
  filename = "${path.module}/certsdir/server_hs3.pem"
}

resource "null_resource" "server_hs3" {
  depends_on = [local_file.server_hs3]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/server_hs3.pem -text -noout > ${path.module}/certsdir/server_hs3.txt"
  }
}

# Empty the local Certs directory, executed only at tf destroy, for cleanup

resource "null_resource" "cleanup" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/certsdir/*"
    when    = destroy
  }
}

