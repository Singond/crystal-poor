.PHONY: check
check:
	crystal spec
	crystal spec spec/import_spec.cr
