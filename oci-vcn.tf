#  Create OCI cloud VCN
resource "oci_core_vcn" "oci-vcn" {
  cidr_blocks    = [var.oci_vcn_cidr_block]
  dns_label      = "ocivcn"
  compartment_id = var.compartment_ocid
  display_name   = "oci-vcn"
}

# Create public subnet for OCI LB
resource "oci_core_subnet" "oci-lbbkend-sb" {
  cidr_block                 = var.oci_subnet_cidr
  display_name               = "oci-lbbkend-sb"
  dns_label                  = "ocilbbksb"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oci-vcn.id
  security_list_ids          = [oci_core_vcn.oci-vcn.default_security_list_id]
  route_table_id             = oci_core_vcn.oci-vcn.default_route_table_id
  dhcp_options_id            = oci_core_vcn.oci-vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_default_security_list" "oci-lbbkend-sb-security-list" {
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.oci-vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "${data.external.public_ip.result.ip_address}/32"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "${oci_core_vcn.oci-vcn.cidr_blocks[0]}"
  }
}

data "oci_core_vcn" "oci-default-route-table-id" {
  vcn_id = oci_core_vcn.oci-vcn.id
}


resource "oci_core_internet_gateway" "IGW" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oci-vcn.id
  display_name   = "IGW"
}

// Create IGW and DRG route rules for OCI VCN default route table
resource "oci_core_default_route_table" "oci-default-route-table" {
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = data.oci_core_vcn.oci-default-route-table-id.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.IGW.id
    destination       = "0.0.0.0/0"
  }
}

# Fetch the public IP using a local-exec provisioner 
data "external" "public_ip" { 
  program = ["sh", "-c", "curl -s https://ipinfo.io/ip | jq -n --arg ip $(cat) '{ip_address: $ip}'"]
}

output "Ur_Public_IP" {
  value = "You can connect to LB and backend servers only from your devbox public IP: \"${data.external.public_ip.result.ip_address}\" "
}