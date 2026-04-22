PYTHON ?= python

.PHONY: install install-dev crawl import-graph run-api compile test check

install:
	$(PYTHON) -m pip install -r requirements.txt

install-dev:
	$(PYTHON) -m pip install -r requirements-dev.txt

crawl:
	$(PYTHON) -m data_pipeline

import-graph:
	$(PYTHON) scripts/import_neo4j.py

run-api:
	uvicorn job_kg.api:app --reload

compile:
	$(PYTHON) -m compileall job_kg data_pipeline scripts

test:
	pytest

check: compile test
