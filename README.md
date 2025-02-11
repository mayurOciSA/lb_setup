## Description
This terraform code is demonstrate the different features of OCI Layer 7 load balancer service.

The setup is simple, load balancer has 3 applications behind it. All applications have same simple [Flask Python WebApp](./ansible/app.py).
All HTTP REST endpoints of this app respond with response which details the input request(itself) to backend application. 
Terraform deploys OCI resources and Ansible deploys the [Flask Python WebApp](./ansible/app.py) on the OCI Computes set aside for each backend set of the load balancer.

For 3 apps, we have 3 listeners hs1, hs2, hs3 with (virtual)hostnames hs1.free.com, hs2.free.com, hs3.free.com .
We demo OCI LB features like path route, rule sets, routing policy etc.

Only hostname hs3(& its listener) has mTLS on front-side(between client & LB). 
Other listeners hs1 and hs2 support only server side TLS.

## Prerequisites
1. Install Terraform
2. Install Ansible
3. Access to Oracle Cloud Infastructure

## How to Deploy

1. Clone the repo to your local machine.
  ```sh
  git clone -b "mTLS" git@github.com:mayurOciSA/lb_setup.git
  ```

2. Copy `local.example.tfvars` as local.tfvars, and update `local.tfvars` with values as suitable to your environment. The contain variable which do not have any default values and hence their values must be provided by you. Please go through [variables.tf](variables.tf). to include any additional and optional configuration variables as per your needs in local.tfvars. You can configure the number of backend servers serving the listener/app with resepctive variable for the listener *backend_hs[1|2|3]_count* in [variables.tf](./variables.tf).

3. Run Terraform
  ```sh
  terraform init
  terraform plan
  terraform apply --var-file=local.tfvars --auto-approve
  ```
4. To tear down the setup
  ```sh
  terraform destroy --var-file=local.tfvars --auto-approve
  ```


## Testing & Exploring
To test mTLS, from tf directory run, the curl command from TF output called *mtls_client_curl*. 
Example TF output below

```sh
Ur_Public_IP = "You can connect to LB and backend servers only from your devbox public IP: \"xx.xxx.xxx.xx\" "
backend_instance_private_ip_hs1 = "10.0.0.88"
backend_instance_private_ip_hs2 = "10.0.0.148"
backend_instance_private_ip_hs3 = "10.0.0.227"
backend_instance_public_ip_hs1 = "xx.101.4.144"
backend_instance_public_ip_hs2 = "xx.101.4.231"
backend_instance_public_ip_hs3 = "xx.101.0.199"
ca_bundle = <<EOT
-----BEGIN CERTIFICATE-----
MIIDdN4KDNuErcyKXOi==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDhjCCAm6gA+p2C+
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDrjJSlzlV4OTcZhA==
-----END CERTIFICATE-----

EOT
get_lb_cli = "Get LB details with OCI CLI Command: oci lb load-balancer get --load-balancer-id 'ocid1.loadbalancer.oc1.phx.xss' --region 'us-phoenix-1' "
lb_public_ip = [
  tolist([
    {
      "ip_address" = "141.xxx.xxx.105"
      "is_public" = true
      "reserved_ip" = tolist([])
    },
  ]),
]
mtls_client_curl = <<EOT

        # Run this on your local machine to test mTLS with curl, from same directory as this terraform script.
        # All the values are pre-filled from terraform outputs, and the certificates are in the certsdir directory.
        # --cacert is Root CA of Server to be trusted by client
        # --cert is client's certificate chain/bundle

        curl -s --resolve hs3.free.com:443:141.xxx.xx.xx --include \
        --cert ./certsdir/client_hs3.pem:./certsdir/intermediate_ca_client.pem \
        --key ./certsdir/client_hs3_key.pem \
        --cacert ./certsdir/root_ca_server.pem https://hs3.free.com:443/get \
        |  awk 'NR <= 6 { print; next } { print | "jq ."}'

EOT        
```


In response you should get value of "X-Client-Cert". example response from virtual host 'hs3' below
Examples response for mTLS, from listener *hs3* below 
```json
{
  "args": {},
  "bk_hs_ip": "10.0.0.76",
  "bk_hs_name": "hs3-bk-0",
  "data": null,
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Host": "hs3.free.com",
    "User-Agent": "curl/8.7.1",
    "X-Client-Cert": "-----BEGIN CERTIFICATE-----dsdfsf-----END CERTIFICATE-----",
    "X-Forwarded-For": "104.xxx.xxx.40",
    "X-Forwarded-Host": "hs3.free.com:443",
    "X-Forwarded-Port": "443",
    "X-Forwarded-Proto": "https",
    "X-Real-Ip": "104.xxx.xxx.40",
    "X-Request-Trace-Id": "ecd19b8ecf4666cbc7028c17545bdeb6"
  },
  "json": null,
  "may_be_lb_backend_pvt_ip": "10.0.0.107",
  "method": "GET",
  "path": "/get"
}
```

