# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| < 0.2   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to [your-email@example.com]. You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information (as much as you can provide) to help us better understand the nature and scope of the possible issue:

* Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
* Full paths of source file(s) related to the manifestation of the issue
* The location of the affected source code (tag/branch/commit or direct URL)
* Any special configuration required to reproduce the issue
* Step-by-step instructions to reproduce the issue
* Proof-of-concept or exploit code (if possible)
* Impact of the issue, including how an attacker might exploit the issue

This information will help us triage your report more quickly.

## Preferred Languages

We prefer all communications to be in English.

## Security Update Process

When we receive a security bug report, we will:

1. Confirm the problem and determine the affected versions
2. Audit code to find any similar problems
3. Prepare fixes for all supported versions
4. Release new versions as quickly as possible

## Security Best Practices for Users

When using WebPark in your applications:

1. **Keep WebPark Updated**: Always use the latest version to benefit from security patches
2. **Protect Tokens**: Never hardcode API tokens or credentials in your source code
3. **Use HTTPS**: Always use HTTPS endpoints, never HTTP for production
4. **Validate Certificates**: Consider implementing certificate pinning for sensitive applications
5. **Handle Errors Securely**: Don't expose sensitive error details to end users
6. **Secure Token Storage**: Store authentication tokens securely (Keychain on Apple platforms)
7. **Implement Token Refresh**: Properly implement token refresh to avoid storing long-lived credentials

## Known Security Considerations

### Token Storage
WebPark does not provide token storage mechanisms. You are responsible for securely storing and managing tokens. We recommend:
- Using Keychain on Apple platforms
- Never storing tokens in UserDefaults or plain files
- Implementing proper token lifecycle management

### Network Security
- WebPark validates that URLs use HTTP/HTTPS schemes
- SSL/TLS is handled by URLSession's default configuration
- For enhanced security, consider implementing certificate pinning

### Dependency Management
WebPark has zero external dependencies, reducing the supply chain attack surface.

## Acknowledgments

We appreciate the security research community's efforts in responsibly disclosing vulnerabilities. Security researchers who report valid vulnerabilities will be acknowledged in our release notes (if they wish).
