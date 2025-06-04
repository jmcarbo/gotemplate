# Contributing to Go Clean Architecture Template

First off, thank you for considering contributing to this template! It's people like you that make this template such a great tool.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- Use a clear and descriptive title
- Describe the exact steps to reproduce the problem
- Provide specific examples to demonstrate the steps
- Describe the behavior you observed and what you expected
- Include screenshots if applicable
- Include your environment details (OS, Go version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- Use a clear and descriptive title
- Provide a detailed description of the proposed enhancement
- Explain why this enhancement would be useful
- List any alternatives you've considered

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure the test suite passes (`make test-template`)
4. Make sure your code follows the project style (`make lint`)
5. Write a good commit message following conventional commits

## Development Process

1. **Setup Development Environment**
   ```bash
   git clone https://github.com/yourusername/gotemplaterepo.git
   cd gotemplaterepo
   make install-tools
   ./scripts/install-hooks.sh
   ```

2. **Make Your Changes**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed
   - Follow SOLID principles and Clean Architecture

3. **Test Your Changes**
   ```bash
   # Run all tests
   make test-template
   
   # Run specific tests
   make test-instantiation
   make test-sync
   ```

4. **Commit Your Changes**
   - Use conventional commit format: `type(scope): description`
   - Types: feat, fix, docs, style, refactor, test, chore
   - Example: `feat(sync): add support for custom hooks`

5. **Submit Pull Request**
   - Update README.md if needed
   - Reference any relevant issues
   - Provide a clear description of changes

## Style Guidelines

### Go Code Style
- Follow standard Go formatting (`gofmt`)
- Use meaningful variable and function names
- Keep functions small and focused
- Document exported functions and types
- Handle errors explicitly

### Template Guidelines
- Maintain backward compatibility when possible
- Document breaking changes clearly
- Keep the template generic and unopinionated
- Provide sensible defaults

### Commit Messages
- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

## Project Structure

When adding new features, follow the existing structure:
- Configuration files go in the root directory
- Scripts go in `scripts/`
- Documentation goes in `docs/`
- Tests go in `test/`
- GitHub-specific files go in `.github/`

## Testing

- Write unit tests for new functionality
- Write integration tests for template features
- Ensure all tests pass before submitting PR
- Aim for good test coverage

## Documentation

- Update relevant documentation
- Add examples for new features
- Keep documentation concise and clear
- Use proper markdown formatting

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for contributing! 🎉