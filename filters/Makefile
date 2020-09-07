FILTERS := $(wildcard *.py)

check:
	-black $(FILTERS)
	-mypy $(FILTERS)
	-flake8 $(FILTERS)
