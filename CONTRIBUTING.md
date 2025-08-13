# Contributing to SportsVerse Academy Management System

Thank you for your interest in contributing to SportsVerse! This document provides guidelines for contributing to the project.

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- Flutter 3.x
- MySQL Database
- Git

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/sportsverse.git`
3. Follow the setup instructions in [README.md](README.md)

## 📋 Development Process

### 1. Choose an Issue
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to let others know you're working on it
- For major changes, create an issue first to discuss the approach

### 2. Create a Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 3. Make Your Changes
- Follow the existing code style and patterns
- Add tests for new functionality
- Update documentation if needed
- Test your changes thoroughly

### 4. Commit Your Changes
```bash
git add .
git commit -m "Add: brief description of your changes"
```

**Commit Message Format:**
- `Add: new feature`
- `Fix: bug description`
- `Update: existing feature improvement`
- `Remove: deprecated functionality`

### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```
Then create a Pull Request on GitHub.

## 🏗️ Code Guidelines

### Backend (Django)
- Follow PEP 8 Python style guidelines
- Use meaningful variable and function names
- Add docstrings to classes and functions
- Use Django best practices for models, views, and serializers
- Ensure all API endpoints have proper error handling

### Frontend (Flutter)
- Follow Dart/Flutter style guidelines
- Use meaningful widget and variable names
- Keep widgets small and focused
- Use Provider for state management
- Add error handling for all API calls

### Database
- Always create migrations for model changes
- Use descriptive migration names
- Test migrations both forward and backward

## 🧪 Testing

### Backend Testing
```bash
cd backend
python manage.py test
```

### Frontend Testing
```bash
cd frontend/sportsverse_app
flutter test
```

## 📝 Documentation

- Update README.md if you change setup process
- Update API documentation for new endpoints
- Add comments for complex logic
- Update DEVELOPMENT_PROGRESS.md for major features

## 🐛 Bug Reports

When reporting bugs, please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- Environment details (OS, Python version, Flutter version)

## 💡 Feature Requests

For new features:
- Describe the feature clearly
- Explain the use case and benefits
- Consider if it fits the project scope
- Be open to discussion and alternative approaches

## 🔍 Code Review Process

1. All changes require a Pull Request
2. At least one review is required before merging
3. Ensure all tests pass
4. Address review feedback promptly
5. Keep PRs focused and reasonably sized

## 📚 Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Python PEP 8 Style Guide](https://pep8.org/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

## 🤝 Community

- Be respectful and inclusive
- Help newcomers get started
- Share knowledge and best practices
- Provide constructive feedback

## 📞 Questions?

If you have questions about contributing:
- Create an issue with the `question` label
- Check existing documentation
- Review similar implementations in the codebase

Thank you for contributing to SportsVerse! 🎉
