.PHONY: fmt validate plan apply destroy clean

fmt:
	terraform fmt -recursive

validate:
	terraform init
	terraform validate

plan: validate
	terraform plan

apply: validate
	terraform plan -out=tfplan
	terraform apply tfplan

destroy:
	terraform destroy

clean:
	rm -rf .terraform terraform.tfstate* *.txt
