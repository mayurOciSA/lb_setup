clear; terraform destroy -var-file=local.tfvars -auto-approve; terraform apply -var-file=local.tfvars -auto-approve

curl --insecure --location --request PUT 'https://<lb_public_ip>/put' --header 'Host: hs1.free.com'

# use postman as per APIs in ./ansible/app.py