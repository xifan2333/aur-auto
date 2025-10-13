## Description
<!-- Provide a clear and concise description of your changes -->

## Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] New package
- [ ] Package update
- [ ] Bug fix
- [ ] CI/Workflow improvement
- [ ] Documentation update
- [ ] Other (please specify):

## Related Issues
<!-- Link to related issues using #issue_number -->
Closes #

## Package Information
<!-- For package-related changes, fill in the following -->
- **Package Name**:
- **Version**:
- **Upstream URL**:

## Checklist

### For All Changes
- [ ] I have read the [packaging guidelines](docs/packaging.en.md)
- [ ] My changes follow the project's coding style and conventions
- [ ] I have updated documentation as needed
- [ ] My commit messages follow the [conventional commits](https://www.conventionalcommits.org/) format

### For New Packages
- [ ] `PKGBUILD` is properly formatted and includes all required fields
- [ ] `.SRCINFO` has been regenerated using `makepkg --printsrcinfo > .SRCINFO`
- [ ] `upstream.sh` implements all required hooks:
  - [ ] `pkg_detect_latest()`
  - [ ] `pkg_get_update_params(version)`
  - [ ] `pkg_update_files(url, filename, pkgver, hash_algo, checksum)`
- [ ] Package builds successfully with `makepkg --cleanbuild --syncdeps`
- [ ] Package installs and runs correctly
- [ ] Desktop integration works (if applicable)
  - [ ] `.desktop` file is valid
  - [ ] Icons are properly installed
  - [ ] Application launches correctly

### For Package Updates
- [ ] `pkgver` has been updated
- [ ] `pkgrel` has been reset to 1 (for version bumps) or incremented (for same version)
- [ ] Checksums have been updated and verified
- [ ] `.SRCINFO` has been regenerated
- [ ] Package builds successfully with the new version
- [ ] Tested that the updated package works correctly

### For `upstream.sh` Changes
- [ ] New interface functions are implemented correctly:
  - [ ] `pkg_get_update_params` returns: `url filename pkgver hash_algo checksum`
  - [ ] `pkg_update_files` accepts: `url filename pkgver hash_algo checksum`
- [ ] Package hook downloads and verifies files correctly
- [ ] Error handling is robust with clear error messages
- [ ] Tested with `scripts/update-package.sh <package_name>`
- [ ] Tested with `scripts/update-package.sh <package_name> --force`

### For CI/Workflow Changes
- [ ] Workflow syntax is valid (tested locally with `act` or verified in CI)
- [ ] Changes are backward compatible with existing packages
- [ ] Documentation has been updated to reflect workflow changes
- [ ] Error handling and logging are appropriate

## Testing
<!-- Describe the testing you have performed -->

### Local Testing
```bash
# Commands used for testing
```

### Build Logs
<!-- Attach build logs or link to CI artifacts -->

## Additional Notes
<!-- Any additional information that reviewers should know -->

## Screenshots
<!-- If applicable, add screenshots to demonstrate the changes -->
