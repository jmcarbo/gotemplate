# Create Use Case

Create a new use case (command or query) following Clean Architecture.

Create a new {{TYPE}} use case called {{USECASE_NAME}} that:
1. Goes in internal/usecases/{{TYPE}}s/ directory
2. Has Input and Output structs
3. Implements Execute method with proper context handling
4. Follows dependency injection pattern for repositories
5. Includes comprehensive unit tests with mocks
6. Has proper error handling and validation
7. Follows the existing patterns from create_user.go
8. Adheres to Interface Segregation Principle