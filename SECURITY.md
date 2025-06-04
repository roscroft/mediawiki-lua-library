# Security Setup Guide

This project has been configured with security best practices. Follow these steps to set up the project securely:

## 1. Environment Configuration

Copy the environment template and customize it:

```bash
cp .env.template .env
```

## 2. Update Passwords and Keys

Edit the `.env` file and change the following values:

### Critical Changes Required:
- `MEDIAWIKI_ADMIN_PASSWORD`: Change from default "admin123"
- `MEDIAWIKI_PROD_PASSWORD`: Change from default "WikiLuaTestAdmin2024#"  
- `MEDIAWIKI_SECRET_KEY`: Generate new key with `openssl rand -hex 32`
- `MEDIAWIKI_UPGRADE_KEY`: Generate new key with `openssl rand -hex 16`

### Example:
```bash
# Generate new secret keys
openssl rand -hex 32  # Use this for MEDIAWIKI_SECRET_KEY
openssl rand -hex 16  # Use this for MEDIAWIKI_UPGRADE_KEY
```

## 3. Template Files

The following files are now templates with environment variable support:

- `LocalSettings.template.php` - MediaWiki configuration template
- `entrypoint.sh` - Uses environment variables instead of hardcoded passwords

## 4. Files Excluded from Git

The `.gitignore` file has been updated to exclude sensitive files:

- `.env` files (except templates)
- `LocalSettings.php` (if it contains secrets)
- Any files with "secret", "password", "credential", "auth" in the name
- API keys, tokens, certificates

## 5. Security Best Practices

1. **Never commit secrets**: Use environment variables or external secret management
2. **Rotate keys regularly**: Generate new secret keys periodically
3. **Use strong passwords**: Minimum 12 characters with mixed case, numbers, symbols
4. **Limit access**: Only grant necessary permissions to users and systems
5. **Monitor access**: Enable logging and review access patterns

## 6. Production Deployment

For production environments:

1. Use a proper secret management system (HashiCorp Vault, AWS Secrets Manager, etc.)
2. Use strong, randomly generated passwords
3. Enable HTTPS/TLS encryption
4. Configure proper database security
5. Set up monitoring and alerting
6. Regular security audits and updates

## 7. Development Environment

For development:

1. Use different passwords than production
2. Keep the `.env` file local only (never commit it)
3. Test with non-sensitive data
4. Regularly update dependencies for security patches

## Troubleshooting

If you encounter issues:

1. Verify `.env` file exists and has correct syntax
2. Check that environment variables are being loaded in `entrypoint.sh`
3. Ensure `LocalSettings.template.php` is being used correctly
4. Review Docker container logs for configuration errors

## Getting Help

If you need assistance with security configuration:

1. Review MediaWiki security documentation
2. Check Docker security best practices
3. Consult your organization's security team
4. Consider professional security audit for production systems
