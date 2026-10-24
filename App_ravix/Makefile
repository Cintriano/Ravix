.PHONY: get gen watch analyze test coverage check

get:
	flutter pub get

# Gera o código do drift e do riverpod (*.g.dart).
gen:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

analyze:
	flutter analyze

test:
	flutter test

# Relatório HTML em coverage/html (precisa do lcov: sudo dnf install lcov).
coverage:
	flutter test --coverage
	genhtml coverage/lcov.info --output-directory coverage/html --quiet
	@echo "Relatório: coverage/html/index.html"

# O mesmo que o CI roda.
check: get gen analyze
	flutter test --coverage
