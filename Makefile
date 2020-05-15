#!make
include .env
export $(shell sed 's/=.*//' .env)

# Setup ————————————————————————————————————————————————————————————————————————
GIT              = git
GIT_AUTHOR       = GNUalex
DOCKER_COMPOSE   = docker-compose
DOCKER_BASH      = ${DOCKER_COMPOSE} exec -u developer -w ${PROJECT_DOCKER_DIR} ${PHP_SERVICE_NAME} bash
DOCKER_BASH_ROOT = ${DOCKER_COMPOSE} exec -w ${PROJECT_DOCKER_DIR} ${PHP_SERVICE_NAME} bash
DOCKER_EXEC      = ${DOCKER_BASH} -c
.DEFAULT_GOAL    = help

## —— 🐝 The amazing Docker Symfony Makefile 🐝 ———————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Composer 🧙‍♂️ ————————————————————————————————————————————————————————————
composer-install: ## Install vendors according to the current composer.lock file
	$(DOCKER_EXEC) 'composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader'

composer-update: ## Update vendors according to the composer.json file
	$(DOCKER_EXEC) 'composer update'

composer-require: ## Install new composer package
	$(DOCKER_EXEC) 'composer require $(package)'

## —— Symfony ———————————————————————————————————————————————————————————————
cc: ## Clear the cache
	$(DOCKER_EXEC) 'bin/console c:c'

warmup: ## Warmup the cache
	$(DOCKER_EXEC) 'bin/console cache:warmup'

assets: cc ## Install the assets with symlinks in the public folder
	$(DOCKER_EXEC) 'bin/console assets:install public/ --symlink --relative'

load-fixtures: ## Build the DB, control the schema validity, load fixtures and check the migration status
	$(DOCKER_EXEC) 'bin/console doctrine:cache:clear-metadata'
	$(DOCKER_EXEC) 'bin/console doctrine:database:create --if-not-exists'
	$(DOCKER_EXEC) 'bin/console doctrine:schema:drop --force'
	$(DOCKER_EXEC) 'bin/console doctrine:schema:create'
	$(DOCKER_EXEC) 'bin/console doctrine:schema:validate'
	$(DOCKER_EXEC) 'bin/console doctrine:fixtures:load -n'

## —— Docker ————————————————————————————————————————————————————————————————
up: ## Start the docker hub
	$(DOCKER_COMPOSE) up -d

upgrade: ## Pull new docker images
	$(DOCKER_COMPOSE) pull
	$(DOCKER_COMPOSE) up -d

down: ## Stop the docker hub
	$(DOCKER_COMPOSE) down --remove-orphans

recreate: ## Recreates the docker hub
	$(DOCKER_COMPOSE) up -d --force-recreate

bash: ## ssh to the php container
	$(DOCKER_BASH)

bash-root: ## ssh to the php container as root
	$(DOCKER_BASH_ROOT)

## —— Tests —————————————————————————————————————————————————————————————————
test: ## Launch main functional and unit tests
	$(DOCKER_EXEC) 'vendor/bin/phpunit --testsuite=main --stop-on-failure'

## —— Coding standards ——————————————————————————————————————————————————————
cs: codesniffer stan ## Launch check style and static analysis

codesniffer: ## Run php_codesniffer only
	$(DOCKER_EXEC) 'vendor/squizlabs/php_codesniffer/bin/phpcs --standard=phpcs.xml -n -p src/'

stan: ## Run PHPStan only
	$(DOCKER_EXEC) 'vendor/bin/phpstan analyse -l max --memory-limit 1G -c phpstan.neon src/'

cs-fix: ## Run php-cs-fixer and fix the code.
	$(DOCKER_EXEC) 'vendor/bin/php-cs-fixer fix src/'

## —— Stats —————————————————————————————————————————————————————————————————
stats: ## Commits by the hour for the main author of this project
	$(GIT) log --author="$(GIT_AUTHOR)" --date=iso | perl -nalE 'if (/^Date:\s+[\d-]{10}\s(\d{2})/) { say $$1+0 }' | sort | uniq -c|perl -MList::Util=max -nalE '$$h{$$F[1]} = $$F[0]; }{ $$m = max values %h; foreach (0..23) { $$h{$$_} = 0 if not exists $$h{$$_} } foreach (sort {$$a <=> $$b } keys %h) { say sprintf "%02d - %4d %s", $$_, $$h{$$_}, "*"x ($$h{$$_} / $$m * 50); }'

## —— Setup —————————————————————————————————————————————————————————————————
setup: ## Copy docker-compose.yaml.tpl with envsubst
	@envsubst < docker-compose.yml.tpl > docker-compose.yml

## —— Create symfony project —————————————————————————————————————————————————————————————————
create: ## Creates a new symfony project
	$(DOCKER_EXEC) 'symfony new ${PROJECT_DOCKER_DIR}'

create-full: ## Creates a new symfony project
	$(DOCKER_EXEC) 'symfony new --full ${PROJECT_DOCKER_DIR}'