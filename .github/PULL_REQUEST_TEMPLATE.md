## 📋 Pull Request Description

### Summary
<!-- Provide a brief summary of the changes -->

### Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Code refactoring (no functional changes)
- [ ] 🧪 Test improvements
- [ ] 🔒 Security improvements
- [ ] ⚡ Performance improvements

### Related Issues
<!-- Link to related issues -->
Fixes #(issue number)
Closes #(issue number)
Related to #(issue number)

## 🧪 Testing

### Test Coverage
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests pass locally

### Test Commands Run
```bash
# List the commands you ran to test your changes
make test
make lint
make security
```

### Test Results
<!-- Paste relevant test output or screenshots -->

## 🔒 Security Checklist

- [ ] No secrets or sensitive information committed
- [ ] Security scans pass (bandit, safety, checkov)
- [ ] Input validation implemented where needed
- [ ] Authentication/authorization properly handled
- [ ] Dependencies are up to date and secure

## 📝 Code Quality Checklist

### Python Code
- [ ] Code follows PEP 8 style guidelines
- [ ] Functions have proper docstrings
- [ ] Type hints added where appropriate
- [ ] Error handling implemented
- [ ] Logging added for debugging

### Terraform Code
- [ ] Code is properly formatted (`terraform fmt`)
- [ ] Variables have descriptions
- [ ] Outputs have descriptions
- [ ] Resource naming follows conventions
- [ ] Security best practices followed

### General
- [ ] Code is self-documenting and readable
- [ ] Complex logic is commented
- [ ] No commented-out code left behind
- [ ] No debug print statements left behind

## 📊 Performance Impact

### Resource Usage
- [ ] No significant increase in resource usage
- [ ] Terraform plan time impact assessed
- [ ] Memory usage impact assessed

### Deployment Time
- [ ] No significant increase in deployment time
- [ ] Changes tested in development environment

## 📚 Documentation

- [ ] README updated if needed
- [ ] CHANGELOG updated
- [ ] API documentation updated
- [ ] Comments added for complex code
- [ ] Migration guide provided (if breaking change)

## 🔄 Deployment Considerations

### Infrastructure Changes
- [ ] Changes are backward compatible
- [ ] Migration strategy documented
- [ ] Rollback plan available
- [ ] Impact on existing deployments assessed

### Configuration Changes
- [ ] New variables documented
- [ ] Default values are sensible
- [ ] Validation rules added
- [ ] Examples provided

## 🧹 Cleanup

- [ ] Temporary files removed
- [ ] Debug code removed
- [ ] Unused imports removed
- [ ] Dead code removed
- [ ] Console.log/print statements removed

## 📸 Screenshots/Logs

### Before
<!-- Screenshots or logs showing the current behavior -->

### After
<!-- Screenshots or logs showing the new behavior -->

## 🎯 Reviewer Focus Areas

<!-- Highlight specific areas where you want reviewer attention -->
- [ ] Security implications of changes
- [ ] Performance impact
- [ ] Error handling
- [ ] Test coverage
- [ ] Documentation accuracy

## 📋 Additional Notes

### Dependencies
<!-- List any new dependencies or version changes -->

### Configuration Changes
<!-- List any configuration changes required -->

### Migration Steps
<!-- If applicable, list steps needed to migrate existing deployments -->

### Known Issues
<!-- List any known issues or limitations -->

## ✅ Final Checklist

- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

---

### For Reviewers

#### Review Checklist
- [ ] Code follows project standards
- [ ] Tests are comprehensive and pass
- [ ] Documentation is accurate and complete
- [ ] Security considerations addressed
- [ ] Performance impact acceptable
- [ ] Breaking changes properly documented

#### Testing Instructions
<!-- Provide step-by-step instructions for reviewers to test the changes -->

1. Checkout the branch
2. Install dependencies: `make install`
3. Run tests: `make test`
4. Verify functionality: [specific steps]

---

**Thank you for contributing to IBM HPC Cluster Symphony! 🚀**
