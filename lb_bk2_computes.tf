resource "oci_core_instance" "lb_bkend_hs2" {
  count               = var.backend_hs2_count

  availability_domain = data.oci_identity_availability_domains.ad_list.availability_domains[count.index % length(data.oci_identity_availability_domains.ad_list.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = "bkend_hs2_${count.index}"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = oci_core_subnet.oci-lbbkend-sb.id
    display_name              = "primary_vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "hs2-bk-${count.index}"
  }
  
  shape_config {
    memory_in_gbs             = var.instance_memory_in_gbs
    ocpus                     = var.instance_ocpus
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_images_oci.images[0].id
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

output "backend_instance_private_ip_hs2" {
  value = one(oci_core_instance.lb_bkend_hs2[*].private_ip)
}

output "backend_instance_public_ip_hs2" {
  value = one(oci_core_instance.lb_bkend_hs2[*].public_ip)
}

resource "time_sleep" "wait_minutes_hs2" {
  count               = var.backend_hs2_count
  depends_on = [oci_core_instance.lb_bkend_hs2]
  create_duration = "0.5m"
}

resource "null_resource" "execute_ansible_playbook_hs2" {
  count               = var.backend_hs2_count
  depends_on = [time_sleep.wait_minutes_hs2]

  // Ansible integration
  provisioner "remote-exec" {
    inline = ["echo About to run Ansible for APP2 deployment!"]

    connection {
      host        = oci_core_instance.lb_bkend_hs2[count.index].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = file("${var.ssh_private_key_local_path}")
    }
  }

  provisioner "local-exec" {
    command = "sleep 20; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u opc -i '${oci_core_instance.lb_bkend_hs2[count.index].public_ip},' --private-key ${var.ssh_private_key_local_path} ./ansible/appdeploy.yml -v"
  }
}

