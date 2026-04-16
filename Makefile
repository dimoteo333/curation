PYTHON ?= python3

bootstrap:
	bash scripts/bootstrap.sh

mobile-lint:
	cd mobile && flutter analyze

mobile-test:
	cd mobile && flutter test

backend-lint:
	$(PYTHON) -m ruff check backend/app backend/tests
	$(PYTHON) -m mypy backend/app

backend-test:
	$(PYTHON) -m pytest backend/tests -q

openapi:
	bash scripts/export-openapi.sh

docs-check:
	bash scripts/validate-docs.sh

ci-local: mobile-lint mobile-test backend-lint backend-test openapi docs-check
