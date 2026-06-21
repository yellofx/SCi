.PHONY: up down build logs shell aider opencode build-app test-app ca-cert help

help:
	@echo "Secure Dev Environment"
	@echo ""
	@echo "  make up          Start the full stack (build images if needed)"
	@echo "  make down        Stop and remove containers"
	@echo "  make down-v      Stop and also delete volumes (target/, maven cache)"
	@echo "  make build       Rebuild dev container image"
	@echo "  make logs        Follow logs of all containers"
	@echo ""
	@echo "  make aider       Enter dev box with Aider coding agent"
	@echo "  make opencode    Enter dev box with OpenCode agent"
	@echo "  make shell       Enter dev box as a plain shell"
	@echo ""
	@echo "  make build-app   Build the sample Spring Boot app inside the box"
	@echo "  make test-app    Build + start app + call /citizens"
	@echo ""
	@echo "  make ca-cert     Generate corp-ca.crt from local system keychain (macOS)"

# --- Lifecycle -----------------------------------------------------------

ca-cert:
	@echo ">> Generating corp-ca.crt from system keychain..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > corp-ca.crt; \
		security find-certificate -a -p /Library/Keychains/System.keychain >> corp-ca.crt 2>/dev/null || true; \
	else \
		cp /etc/ssl/certs/ca-certificates.crt corp-ca.crt; \
	fi
	@echo ">> corp-ca.crt ready ($$(grep -c 'END CERT' corp-ca.crt) certs)"

up: corp-ca.crt .env
	./scripts/up.sh

corp-ca.crt:
	$(MAKE) ca-cert

.env:
	@echo ">> Creating .env from template — edit secrets before production use"
	cp .env.example .env

down:
	./scripts/down.sh

down-v:
	./scripts/down.sh -v

build:
	podman-compose build --no-cache dev

logs:
	podman-compose logs -f

# --- Agent entry points --------------------------------------------------

aider:
	./scripts/agent.sh aider

opencode:
	./scripts/agent.sh opencode

shell:
	./scripts/agent.sh shell

# --- App -----------------------------------------------------------------

build-app:
	podman exec sde-dev mvn -q -f /workspace/pom.xml package -DskipTests

test-app: build-app
	@echo ">> Starting app..."
	podman exec -d sde-dev bash -lc \
		'mvn -q spring-boot:run \
		  -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005" \
		  -f /workspace/pom.xml'
	@echo ">> Waiting for app to be ready..."
	@for i in $$(seq 1 30); do \
		curl -sf http://localhost:8080/citizens >/dev/null 2>&1 && break || sleep 2; \
	done
	@echo ">> GET /citizens:"
	@curl -s http://localhost:8080/citizens | python3 -m json.tool
