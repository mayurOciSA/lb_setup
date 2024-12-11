resource "oci_load_balancer" "lb" {
    compartment_id = var.compartment_ocid
    display_name = "lb_007"
    subnet_ids = [oci_core_subnet.oci-lbbkend-sb.id] # single regional subnet #askTim, if AD-specific subnet array, each AD gets seperate IP for LB?

    is_delete_protection_enabled = false
    is_private = false
    ip_mode = "IPV4" #askTim is IPV6 basically both? we get 2 IPs?

    is_request_id_enabled = true
    request_id_header = "X-request-trace-id"

    shape = "flexible"
    shape_details {
        maximum_bandwidth_in_mbps = 10
        minimum_bandwidth_in_mbps = 10
    }
    
}

output "lb_public_ip" {
  value = [oci_load_balancer.lb.ip_address_details]
}

output "get_lb_cli" {
  value = "Get LB details with OCI CLI Command: oci lb load-balancer get --load-balancer-id '${oci_load_balancer.lb.id}' --region '${var.oci_region}' "
}








