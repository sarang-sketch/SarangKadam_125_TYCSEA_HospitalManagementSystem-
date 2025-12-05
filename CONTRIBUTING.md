# Contributing to Hospital Management System

Thank you for your interest in contributing to this project! Here's how you can help.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](../../issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Your environment (PHP version, MySQL version, browser)

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue with the "enhancement" label
3. Describe the feature and its use case

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages: `git commit -m "Add: feature description"`
6. Push to your fork: `git push origin feature/your-feature-name`
7. Open a Pull Request

## Code Standards

### PHP
- Use PHP 8+ features where appropriate
- Follow PSR-12 coding standards
- Use prepared statements for all database queries
- Sanitize all user inputs
- Add comments for complex logic

### HTML/CSS
- Use semantic HTML5
- Follow Bootstrap conventions
- Keep custom CSS minimal and organized
- Ensure responsive design

### JavaScript
- Use vanilla JS (no jQuery dependency)
- Add comments for complex functions
- Handle errors gracefully

## Testing

Before submitting:
1. Test all affected features manually
2. Verify on multiple browsers (Chrome, Firefox, Edge)
3. Check responsive design on mobile
4. Ensure no PHP errors/warnings

## Commit Message Format

```
Type: Short description

Longer description if needed.

Fixes #issue_number (if applicable)
```

Types: `Add`, `Fix`, `Update`, `Remove`, `Refactor`, `Docs`

## Questions?

Open an issue with the "question" label.

Thank you for contributing! 🏥
