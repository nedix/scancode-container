setup:
	@docker build --progress=plain -f Containerfile -t scancode .

run:
	@docker run --rm -it --name="scancode" \
		scancode

test:
	@$(CURDIR)/tests/index.sh
