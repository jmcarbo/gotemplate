# Add Integration Test

Create integration tests for a feature.

Create integration tests for {{FEATURE_NAME}}:
1. Place in test/integration/
2. Use test containers for external dependencies
3. Test the full flow from adapter to infrastructure
4. Include both happy path and error cases
5. Use test fixtures for data setup
6. Ensure proper cleanup after tests
7. Test transaction rollback scenarios
8. Verify side effects (database state, events, etc.)