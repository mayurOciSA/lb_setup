tenancy_ocid = "ocid1.tenancy.oc1....."
# mayurcmpt/load_balancer
compartment_ocid          = "ocid1.compartment.oc1.."
oci_region                = "us-phoenix-1"

user_ocid        = "ocid1.user.oc1.."
fingerprint      = "11:26:47:............"
private_key_path = "/Users/<home>/.oci/oci_api_key.pem"

# ssh_public_key and ssh_private_key_local_path are public and private keys from the same/one pair
# ssh_public_key is string format of the public key
# ssh_private_key_local_path is the path to the private key file, on your system/devbox

ssh_public_key             = "ssh-rsa "
ssh_private_key_local_path = "/Users/<home>/.ssh/id_rsa"

# ssh_private_key_local_path = <<-EOT
# -----BEGIN RSA PRIVATE KEY-----
# 
# -----END RSA PRIVATE KEY-----
# EOT