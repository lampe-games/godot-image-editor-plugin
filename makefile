all: lint format-check shaders-format-check

cloc:
	cloc .

gource:
	gource . --key -s 1.5 -a 0.1

format:
	find -name '*.gd' | xargs gdformat

format-check:
	find -name '*.gd' | xargs gdformat --check

shaders-format-check:
	find -name '*.shader' | xargs clang-format --style=file --dry-run -Werror

lint:
	find -name '*.gd' | xargs gdlint
