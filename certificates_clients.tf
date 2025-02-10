# Root CA for Client side certificates

resource "tls_private_key" "root_ca_client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "root_ca_client" {
  private_key_pem = tls_private_key.root_ca_client.private_key_pem
  subject {
      common_name  = "client-root-example-ca"
      organization = "client Root Example CA"
    }

  validity_period_hours = 24 * 5
  is_ca_certificate     = true
  allowed_uses = [
     "key_encipherment", "digital_signature", "cert_signing", 
     "server_auth", "client_auth", "code_signing", "email_protection", 
     "ipsec_end_system", "ipsec_tunnel", "ipsec_user", "timestamping",
  ]
}

# Intermediate CA for Client side certificates
resource "tls_private_key" "intermediate_ca_client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "intermediate_ca_client" { 
  private_key_pem = tls_private_key.intermediate_ca_client.private_key_pem
  subject {
      common_name  = "intermediate_ca_client example.com"
      organization = "intermediate_ca_client Example"
    }
}

resource "tls_locally_signed_cert" "intermediate_ca_client" {
  ca_private_key_pem   = tls_private_key.root_ca_client.private_key_pem
  ca_cert_pem          = tls_self_signed_cert.root_ca_client.cert_pem
  
  cert_request_pem     = tls_cert_request.intermediate_ca_client.cert_request_pem

  validity_period_hours = 24 * 3
  is_ca_certificate    = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# Client's certificate, only for listener/app hs3, for mTLS

resource "tls_private_key" "client_hs3" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_hs3" {
  private_key_pem = tls_private_key.client_hs3.private_key_pem
  subject {
      // can be anything, servers typically do not 'check' client's CN(in mTLS), but clients do check server's CN always(TLS or mTLS)
      common_name  = "client_hs3 example.com" 
      organization = "client_hs3 Example"
    }
}

resource "tls_locally_signed_cert" "client_hs3" {
  ca_private_key_pem   = tls_private_key.intermediate_ca_client.private_key_pem
  ca_cert_pem          = tls_locally_signed_cert.intermediate_ca_client.cert_pem

  cert_request_pem     = tls_cert_request.client_hs3.cert_request_pem
  validity_period_hours = 24 * 3
  is_ca_certificate    = false
  allowed_uses = [
    "digital_signature", "server_auth", "client_auth",
  ]
}

# Create local copies for certificates in client's chain, in local directory certsdir


resource "local_file" "root_ca_client" {
  content  = tls_self_signed_cert.root_ca_client.cert_pem
  filename = "${path.module}/certsdir/root_ca_client.pem"
}

resource "null_resource" "root_ca_client" {
  depends_on = [local_file.root_ca_client]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/root_ca_client.pem -text -noout > ${path.module}/certsdir/root_ca_client.txt"
  }
}

resource "local_file" "intermediate_ca_client" {
  content  = tls_locally_signed_cert.intermediate_ca_client.cert_pem
  filename = "${path.module}/certsdir/intermediate_ca_client.pem"
}

resource "null_resource" "intermediate_ca_client" {
  depends_on = [local_file.intermediate_ca_client]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/intermediate_ca_client.pem -text -noout > ${path.module}/certsdir/intermediate_ca_client.txt"
  }
}

resource "local_file" "client_hs3" {
  content  = tls_locally_signed_cert.client_hs3.cert_pem
  filename = "${path.module}/certsdir/client_hs3.pem"
}

resource "local_file" "client_hs3_key" {
  content = tls_private_key.client_hs3.private_key_pem
  filename = "${path.module}/certsdir/client_hs3_key.pem"
}

resource "null_resource" "client_hs3" {
  depends_on = [local_file.client_hs3]

  provisioner "local-exec" {
    command = "openssl x509 -in ${path.module}/certsdir/client_hs3.pem -text -noout > ${path.module}/certsdir/client_hs3.txt"
  }
}

output "mtls_client_curl" {


  value = <<EOF

        # Run this on your local machine to test mTLS with curl, from same directory as this terraform script.
        # All the values are pre-filled from terraform outputs, and the certificates are in the certsdir directory.
        # --cacert is Root CA of Server to be trusted by client
        # --cert is client's certificate chain/bundle

        curl -s --resolve hs3.free.com:443:${oci_load_balancer.lb.ip_address_details[0].ip_address} --include \
        --cert ${path.module}/certsdir/client_hs3.pem:${path.module}/certsdir/intermediate_ca_client.pem \
        --key ${path.module}/certsdir/client_hs3_key.pem \
        --cacert ${path.module}/certsdir/root_ca_server.pem https://hs3.free.com:443/get \
        |  awk 'NR <= 6 { print; next } { print | "jq ."}'

  EOF
}
