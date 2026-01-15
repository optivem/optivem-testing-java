# Smoke Test Release Module

This module contains smoke tests for verifying release versions of the optivem-test library.

## Purpose

The smoke-test-release module is designed to verify the basic functionality of official release versions, including:

- Library loading verification for stable releases
- Basic class accessibility tests
- Release version dependency resolution

## Structure

- `src/main/java/` - Main source code (if needed for test utilities)
- `src/test/java/` - Smoke test implementations for release versions

## Running Tests

To run the release smoke tests:
```bash
./gradlew system-test:smoke-test-release:test
```

To verify dependencies can be resolved:
```bash
./gradlew system-test:smoke-test-release:verifyDependencies
```

## Dependencies

This module depends on:
- The main `optivem-test` library (release version)
- JUnit Jupiter for test framework

## Difference from smoke-test-rc

- **smoke-test-rc**: Tests release candidate versions (RC builds)
- **smoke-test-release**: Tests stable release versions