ifeq ($(OS),Windows_NT)
SHELL := powershell.exe
.SHELLFLAGS := -NoProfile -Command
endif

docker_create_instance_build:
	docker buildx create --name apps_builder
	docker buildx use apps_builder
	docker buildx ls
	docker buildx inspect --bootstrap

docker_build_linux:
	docker buildx use apps_builder
	export $(cat .env | xargs)
	echo "${PB_VERSION}"
	echo "${POCKETBASE_VERSION}"
	docker buildx build . --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6,darwin/amd64 --push -t gladson/pocketbase:latest
	docker buildx build . --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6,darwin/amd64 --push -t gladson/pocketbase:"${POCKETBASE_VERSION}"

docker_build_win:
	docker buildx use apps_builder
	.\set_env.ps1
	$$Env:PB_VERSION
	$$Env:POCKETBASE_VERSION
	docker buildx build . --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6,darwin/amd64 --push -t gladson/pocketbase:latest
	docker buildx build . --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6,darwin/amd64 --push -t gladson/pocketbase:$$Env:POCKETBASE_VERSION