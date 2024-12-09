resource "oci_logging_log_group" "lb_log_group" {
    compartment_id = var.compartment_ocid
    display_name = "lb_log_group"
}

resource "oci_logging_log" "lb_access_log" {
    display_name = "lb_access_log"
    log_group_id = oci_logging_log_group.lb_log_group.id
    log_type = "SERVICE"
    configuration {
        source {
            category = "access"
            resource = oci_load_balancer.lb.id
            service = "loadbalancer"
            source_type = "OCISERVICE"
        }
        compartment_id = var.compartment_ocid
    }
    is_enabled = true
}

resource "oci_logging_log" "lb_error_log" {
    display_name = "lb_error_log"
    log_group_id = oci_logging_log_group.lb_log_group.id
    log_type = "SERVICE"
    configuration {
        source {
            category = "error"
            resource = oci_load_balancer.lb.id
            service = "loadbalancer"
            source_type = "OCISERVICE"
        }
        compartment_id = var.compartment_ocid
    }
    is_enabled = true
}