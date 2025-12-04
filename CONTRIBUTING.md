# Contributing to EasitOpen

Thank you for your interest in contributing! This guide will help you get started.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Code Guidelines](#code-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [SwiftData Migrations](#swiftdata-migrations)

## Getting Started

### Prerequisites

- macOS with Xcode 15.0+
- iOS 17.0+ SDK
- Git
- Google Places API key (for testing)
- Basic knowledge of Swift, SwiftUI, and SwiftData

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/EasitOpen.git
   cd EasitOpen
   ```

2. **Configure API Key**
   ```bash
   cp EasitOpen/Config.swift.template EasitOpen/Config.swift
   # Edit Config.swift with your test API key
   ```

3. **Open in Xcode**
   ```bash
   open EasitOpen.xcodeproj
   ```

4. **Enable Background Refresh** (optional, see BACKGROUND_REFRESH_SETUP.md)

5. **Run Tests**
   - Press Cmd+U or Product > Test
   - Ensure all 62+ tests pass

## How to Contribute

### Reporting Bugs

Found a bug? Please create an issue with:

- **Clear title** - Describe the problem concisely
- **Steps to reproduce** - How to trigger the bug
- **Expected behavior** - What should happen
- **Actual behavior** - What actually happens
- **Environment** - iOS version, device type, app version
- **Screenshots** - If applicable

### Suggesting Features

Have an idea? Create an issue with:

- **Problem statement** - What user need does this address?
- **Proposed solution** - How would it work?
- **Alternatives considered** - Other approaches you thought of
- **Mockups** - UI sketches if applicable

### Contributing Code

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow existing patterns
   - Add tests for new functionality
   - Update documentation

3. **Test thoroughly**
   - Run all unit tests (Cmd+U)
   - Test on simulator and device if possible
   - Check for memory leaks (Instruments)
   - Verify no compiler warnings

4. **Commit**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a Pull Request on GitHub

## Code Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use descriptive variable and function names
- Add comments for complex logic (explain *why*, not *what*)
- Keep functions small and focused
- Use SwiftUI best practices

### File Organization

```
EasitOpen/
├── Models/          # Data models (@Model classes)
├── Views/           # SwiftUI views
├── Services/        # Business logic, API clients
└── EasitOpenApp.swift
```

### Naming Conventions

- **Classes/Structs**: PascalCase (e.g., `BusinessCard View`)
- **Functions/Variables**: camelCase (e.g., `refreshBusiness`)
- **Constants**: camelCase (e.g., `closingSoonThreshold`)
- **Enums**: PascalCase cases (e.g., `BusinessStatus.closingSoon`)

### Code Comments

```swift
// Good: Explains why
// Use 60-minute threshold to give users enough time to reach businesses
let closingSoonThreshold = 60

// Bad: States the obvious
// Set threshold to 60
let closingSoonThreshold = 60
```

## Testing

### Running Tests

```bash
# Command line
xcodebuild test -project EasitOpen.xcodeproj -scheme EasitOpen -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: Cmd+U
```

### Writing Tests

- Add tests for all new features
- Test edge cases and error conditions
- Use descriptive test names: `testBusinessStatusClosingSoonAt60Minutes()`
- Keep tests focused and independent

Example:
```swift
func testBusinessStatusClosingSoonWhenClosingIn45Minutes() {
    let business = createTestBusiness(closingInMinutes: 45)
    XCTAssertEqual(business.status, .closingSoon)
}
```

### Test Coverage

- Aim for >80% code coverage
- All business logic should be tested
- UI tests are optional but welcome

## Pull Request Process

### Before Submitting

- [ ] All tests pass
- [ ] No compiler warnings
- [ ] Code follows style guidelines
- [ ] Documentation updated (if needed)
- [ ] Tested on simulator and device (if possible)

### PR Description Template

```markdown
## Description
Brief summary of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How Has This Been Tested?
- Tested on iOS Simulator (iPhone 15, iOS 17.0)
- Tested on physical device (iPhone 14, iOS 17.2)
- All unit tests pass

## Screenshots (if applicable)
[Add screenshots here]

## Related Issues
Closes #123
```

### Review Process

1. Maintainer will review your PR
2. Address any feedback or requested changes
3. Once approved, PR will be merged
4. Your contribution will be credited in release notes

## SwiftData Migrations

**IMPORTANT**: Changes to `@Model` classes can cause data loss if not handled properly.

### Safe Changes ✅

These won't cause data loss:

- Adding **optional** properties with defaults
  ```swift
  var newField: String? = nil
  ```
- Adding computed properties
- Adding methods
- UI-only changes

### Dangerous Changes ⚠️

These require migration planning:

- Adding **required** properties (no default)
- Renaming properties
- Changing property types
- Removing properties

**If you need to make dangerous changes:**

1. Read `DATA_MIGRATION_GUIDE.md` first
2. Discuss in an issue before implementing
3. Add migration plan
4. Test on fresh install AND upgrade
5. Document in PR and release notes

### Example: Safe Addition

```swift
@Model
class Business {
    // Existing properties...
    
    // ✅ Safe - optional with default
    var isFavorite: Bool = false
}
```

### Example: Requires Migration

```swift
// ⚠️ Dangerous - renaming property
@Model
class Business {
    // Old: var phoneNumber: String?
    
    // Need migration!
    @Attribute(.originalName("phoneNumber"))
    var phone: String?
}
```

## Areas Needing Help

Current priorities for contributors:

- **Testing**: More unit and integration tests
- **Accessibility**: VoiceOver support, Dynamic Type
- **Performance**: Optimization opportunities
- **Documentation**: Code comments, user guides
- **UI Polish**: Animations, dark mode improvements
- **Localization**: Translation support

## Questions?

- Check existing [Issues](https://github.com/NissimAmira/EasitOpen/issues) and [Discussions](https://github.com/NissimAmira/EasitOpen/discussions)
- Open a new issue with "question" label
- Review documentation files

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers and beginners
- Focus on the code, not the person
- Provide helpful feedback
- Have fun and learn together!

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Recognition

Contributors will be acknowledged in:
- Release notes
- README (for significant contributions)
- Git commit history

Thank you for contributing to EasitOpen! 🎉
