bootstrap:
	bash scripts/bootstrap.sh

mobile-lint:
	cd mobile && flutter analyze

mobile-test:
	cd mobile && flutter test

backend-lint:
	python -m ruff check backend/app backend/tests
	python -m mypy backend/app

backend-test:
	python -m pytest backend/tests -q

openapi:
	bash scripts/export-openapi.sh

docs-check:
	bash scripts/validate-docs.sh

ci-local: mobile-lint mobile-test backend-lint backend-test openapi docs-check