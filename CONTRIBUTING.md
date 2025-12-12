# Contributing to Users Timeline

Thank you for your interest in contributing to Users Timeline! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Flutter 3.x or later
- Dart SDK
- Git
- Understanding of property-based testing principles

### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/users-timeline-app.git
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate code:
   ```bash
   flutter packages pub run build_runner build
   ```

## 🏗️ Architecture Guidelines

### Feature-Based Structure

The project follows a feature-based architecture. When adding new features:

```
lib/features/your_feature/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── providers/
└── services/
```

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add documentation for public APIs
- Keep functions small and focused
- Use const constructors where possible

## 🧪 Testing Requirements

### Property-Based Testing

All new features MUST include property-based tests:

```dart
/**
 * Feature: feature-name, Property X: Property Description
 * 
 * Property: For any [input condition], the system should [expected behavior]
 * 
 * Validates: Requirements X.Y
 */
test('Property: Description for any input', () {
  for (int i = 0; i < 100; i++) {
    // Generate random test data
    final input = generateRandomInput();
    
    // Test the property
    final result = systemUnderTest(input);
    
    // Verify the property holds
    expect(result, satisfiesProperty);
  }
});
```

### Test Coverage

- Minimum 100 iterations for property-based tests
- Unit tests for specific edge cases
- Integration tests for user flows
- All tests must pass before merging

## 📝 Commit Guidelines

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(stories): add scrollytelling synchronization
fix(timeline): resolve clustering algorithm edge case
test(media): add property tests for EXIF extraction
```

## 🔄 Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow architecture guidelines
   - Add comprehensive tests
   - Update documentation

3. **Test your changes**:
   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**:
   - Use the PR template
   - Link related issues
   - Add screenshots for UI changes
   - Ensure all checks pass

## 📋 Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Property-based tests added/updated
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests pass

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

## 🐛 Bug Reports

When reporting bugs, include:

1. **Environment**:
   - Flutter version
   - Dart version
   - Platform (iOS/Android)
   - Device information

2. **Steps to Reproduce**:
   - Clear, numbered steps
   - Expected vs actual behavior
   - Screenshots/videos if applicable

3. **Additional Context**:
   - Error messages
   - Logs
   - Related issues

## 💡 Feature Requests

For new features:

1. **Use Case**: Describe the problem you're solving
2. **Proposed Solution**: Your suggested approach
3. **Alternatives**: Other solutions considered
4. **Requirements**: Any specific requirements or constraints

## 🔒 Security

If you discover a security vulnerability:

1. **DO NOT** open a public issue
2. Email the maintainers directly
3. Include detailed information about the vulnerability
4. Allow time for the issue to be addressed before disclosure

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Property-Based Testing](https://hypothesis.works/articles/what-is-property-based-testing/)
- [Riverpod Documentation](https://riverpod.dev/)

## 🤝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain a positive environment

## 📞 Getting Help

- Open an issue for bugs or feature requests
- Join discussions in existing issues
- Check documentation and examples first
- Be patient and respectful when asking for help

Thank you for contributing to Users Timeline! 🎉