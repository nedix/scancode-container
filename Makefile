setup:
	@docker build --progress=plain -f Containerfile -t scancode .

shell:
	@docker run --rm -it --name="scancode" \
		scancode

test:
	@$(CURDIR)/tests/index.sh
