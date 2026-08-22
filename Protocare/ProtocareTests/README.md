# Protocare Unit Tests

This directory contains the unit test suite for the Protocare iOS app.

## Test Structure

```
ProtocareTests/
├── Mocks/                          # Mock implementations for testing
│   ├── MockAuthAPI.swift          # Mock API client
│   └── MockAuthStore.swift        # Mock auth store
├── Utils/                          # Test utilities
│   └── TestFixtures.swift         # Sample test data
├── Extensions/                     # Extension tests
│   ├── StringValidationTests.swift
│   ├── DoubleFormattingTests.swift
│   └── ActionItemEnrichmentTests.swift
└── ViewModels/                     # ViewModel tests
    └── LoginViewModelTests.swift
```

## Running Tests

### From Xcode
1. Select the Protocare scheme
2. Press Cmd+U or go to Product > Test

### From Command Line
```bash
cd /Users/alex/Pets/protocare_mobile/Protocare
xcodebuild -scheme Protocare -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Test Coverage

### Extensions Tests
- **StringValidationTests**: Email validation regex
- **DoubleFormattingTests**: Number formatting with fraction digits
- **ActionItemEnrichmentTests**: Substance resolution logic

### ViewModel Tests
- **LoginViewModelTests**: Login flow, validation, error handling

### Mock Objects
- **MockAuthAPI**: Configurable mock API with success/failure results
- **MockAuthStore**: Mock auth state with test hooks

## Adding New Tests

1. Create test file in appropriate subdirectory
2. Import XCTest and @testable import Protocare
3. Follow naming convention: `test[Method]_[Condition]_[ExpectedResult]`
4. Use MockAuthAPI and MockAuthStore for dependencies
5. Use TestFixtures for sample data

## OpenAPI Schema

Tests are based on the backend API defined in `../openapi.json`:
- POST /auth/register - Returns 201 (success) or 422 (validation error)
- POST /auth/login - Returns 200 (success) or 401 (unauthorized)
- GET /protocols - Requires authentication
- GET /actions - Returns list of actions
- GET /substances - Returns list of substances

Password requirements: min 8, max 128 characters
