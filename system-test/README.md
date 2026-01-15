# System Test Module

This module contains system-level tests for the Optivem Test Java project.

## Purpose

The system-test module is designed to run comprehensive end-to-end tests that verify the entire system's behavior, including:

- Integration tests across multiple modules
- System-level functionality verification
- End-to-end workflows testing

## Structure

- `src/main/java/` - Main source code (if needed for test utilities)
- `src/test/java/` - System test implementations
- `smoke-test-rc/` - Smoke tests for release candidate verification

## Submodules

### smoke-test-rc
Smoke tests designed to verify the basic functionality of release candidate versions.

### smoke-test-release
Smoke tests designed to verify the basic functionality of stable release versions.

## Running Tests

To run all system tests:
```bash
./gradlew system-test:test
```

To run smoke tests for RC versions:
```bash
./gradlew system-test:smoke-test-rc:test
```

To run smoke tests for release versions:
```bash
./gradlew system-test:smoke-test-release:test
```

## Dependencies

This module depends on:
- The main `optivem-test` library
- JUnit for test framework