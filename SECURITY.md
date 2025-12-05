# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please do the following:

1. **Do NOT** open a public issue
2. Email the maintainers directly with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Best Practices

When deploying this system:

### Database
- Change default MySQL root password
- Create a dedicated database user with limited privileges
- Use strong, unique passwords

### Application
- Change all default user passwords immediately after installation
- Use HTTPS in production
- Keep PHP and MySQL updated
- Set proper file permissions (755 for directories, 644 for files)

### Server
- Configure firewall rules
- Disable directory listing
- Remove or protect phpMyAdmin in production
- Enable PHP error logging (disable display_errors)

### Configuration
```php
// In production, add to config/database.php:
ini_set('display_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);
```

## Security Features Implemented

- ✅ Password hashing with bcrypt
- ✅ Prepared statements (SQL injection prevention)
- ✅ Output escaping (XSS prevention)
- ✅ Session-based authentication
- ✅ Role-based access control
- ✅ Input validation and sanitization

## Known Limitations

- No CSRF token implementation (recommended for production)
- No rate limiting on login attempts
- No two-factor authentication
- Session timeout not configurable

These should be addressed before deploying to a production environment with sensitive data.
