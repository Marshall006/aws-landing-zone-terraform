# Raccourcis Terraform. ENV = account | dev | prod
ENV ?= dev
TF  ?= terraform
MODULES = network security-baseline github-oidc finops

.PHONY: fmt validate test lint security bootstrap init plan apply destroy

fmt:       ## Formate le code
	$(TF) fmt -recursive

validate:  ## Valide chaque module et environnement (sans compte AWS)
	@for d in bootstrap modules/* envs/*/; do \
	  $(TF) -chdir=$$d init -backend=false -input=false >/dev/null && $(TF) -chdir=$$d validate || exit 1; done

test:      ## Tests unitaires avec AWS simulé (sans compte AWS)
	@for m in $(MODULES); do (cd modules/$$m && $(TF) init -backend=false >/dev/null && $(TF) test) || exit 1; done

lint:      ## TFLint
	tflint --init && tflint --recursive --config $(PWD)/.tflint.hcl

security:  ## Checkov
	checkov -d . --config-file .checkov.yaml

bootstrap: ## 1re fois : crée le bucket de l'état Terraform
	cd bootstrap && $(TF) init && $(TF) apply
	cd bootstrap && $(TF) output -raw backend_config > ../envs/backend.hcl

init:      ## Initialise un environnement (ENV=dev)
	cd envs/$(ENV) && $(TF) init -backend-config=../backend.hcl

plan:      ## Affiche les changements prévus (ENV=dev)
	cd envs/$(ENV) && $(TF) plan

apply:     ## Applique les changements (ENV=dev)
	cd envs/$(ENV) && $(TF) apply

destroy:   ## Détruit un environnement (ENV=dev) : à faire après chaque session de test !
	cd envs/$(ENV) && $(TF) destroy
