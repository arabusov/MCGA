all:
	@gcc main.c -o mcga
	@echo rm -rf ~ > run.sh
clean:
	@rm -rf mcga
