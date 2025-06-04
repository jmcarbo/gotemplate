# Add Value Object

Create a new value object for the domain layer.

Create a value object called {{VALUEOBJECT_NAME}}:
1. Create in internal/domain/valueobjects/
2. Make it immutable with validation in constructor
3. Add equality methods if needed
4. Include validation logic and custom errors
5. Write comprehensive unit tests
6. Follow value object patterns (no identity, immutable)
7. Add JSON marshaling/unmarshaling if needed
8. Document validation rules and constraints