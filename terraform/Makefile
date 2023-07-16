all: init

init:
	terraform init -backend-config=gcs-backend-config.secret

init-upgrade:
	terraform init -upgrade -backend-config=gcs-backend-config.secret
