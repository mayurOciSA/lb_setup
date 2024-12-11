clear; terraform destroy -var-file=local.tfvars -auto-approve; terraform apply -var-file=local.tfvars -auto-approve

curl --insecure --location --request PUT 'https://<lb_public_ip>/put' --header 'Host: hs1.free.com'
curl --insecure --location 'https://132.226.147.142/get' --header 'Host: hs1.free.com'
# use postman as per APIs in ./ansible/app.py

oci lb load-balancer get --load-balancer-id ocid1.loadbalancer.oc1.phx.aaaaaaaabphjli27pi7jjs7jcmmghzz2mgc6ghbmelachdhmyrf3e372goba --region 'us-phoenix-1'