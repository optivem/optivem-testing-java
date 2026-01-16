# Smoke Test RC Maven Central

This module contains smoke tests that verify the Maven Central RC version of optivem-test library.

## Purpose

- Tests the published RC version from Maven Central
- Ensures RC builds are correctly published and accessible via Maven Central
- Validates basic functionality of the RC artifacts

## Running Tests

```bash
./gradlew system-test:smoke-test-rc-mavencentral:test
```