.PHONY: get gen watch analyze test coverage check

get:
	flutter pub get

# Gera o código do drift e do riverpod (*.g.dart).
gen:
	dart run build_runner build

watch:
	dart run build_runner watch

analyze:
	flutter analyze

test:
	flutter test

# Relatório HTML em coverage/html, sem o código gerado (precisa do lcov:
# sudo dnf install lcov).
coverage:
	flutter test --coverage
	lcov --quiet --remove coverage/lcov.info '*.g.dart' --output-file coverage/lcov.info
	genhtml coverage/lcov.info --output-directory coverage/html --quiet
	@echo "Relatório: coverage/html/index.html"

# O mesmo que o CI roda.
check: get gen analyze
	flutter test --coverage
