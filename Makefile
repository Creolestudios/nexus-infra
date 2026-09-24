.PHONY: init plan apply destroy seed-logs full-deploy fmt validate outputs

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

seed-logs:
	python3 scripts/seed_logs.py

full-deploy: apply seed-logs

fmt:
	terraform fmt -recursive

validate:
	terraform validate

outputs:
	terraform output
