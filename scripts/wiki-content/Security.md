# Security Guide

Security configuration and best practices for the MediaWiki Lua Module Library.

## Security Configuration

### Environment Variables

**Required secure configuration:**

```bash
# Copy environment template
cp .env.template .env

# Generate secure keys
openssl rand -hex 32  # Use for MEDIAWIKI_SECRET_KEY
openssl rand -hex 16  # Use for MEDIAWIKI_UPGRADE_KEY
```

**Environment file (`.env`):**
```bash
# Change these from defaults:
MEDIAWIKI_ADMIN_PASSWORD=your_secure_password
MEDIAWIKI_PROD_PASSWORD=your_secure_password  
MEDIAWIKI_SECRET_KEY=generated_32_char_hex
MEDIAWIKI_UPGRADE_KEY=generated_16_char_hex

# Database configuration
MYSQL_ROOT_PASSWORD=secure_root_password
MYSQL_PASSWORD=secure_user_password
```

### Security Principles

- **No hardcoded secrets**: All sensitive data in environment variables
- **Template-based configuration**: `.env.template` for reference
- **Secrets excluded**: `.gitignore` prevents accidental commits
- **Environment isolation**: Development vs production separation

## Best Practices

### Development Security

1. **Never commit `.env` files**
2. **Use strong, unique passwords**
3. **Regenerate keys for production**
4. **Review dependencies regularly**
5. **Keep Docker images updated**

### Production Deployment

```bash
# Generate production keys
openssl rand -hex 32 > mediawiki_secret.key
openssl rand -hex 16 > mediawiki_upgrade.key

# Set secure file permissions
chmod 600 *.key
chmod 600 .env
```

### Security Scanning

GitHub Actions automatically:
- Scans for security vulnerabilities
- Updates dependencies via Dependabot
- Runs security audits on code changes
- Monitors for exposed secrets

## Common Security Issues

### Issue: Exposed Secrets
**Solution**: Use environment variables and `.gitignore`

### Issue: Weak Passwords
**Solution**: Generate strong passwords with `openssl rand`

### Issue: Outdated Dependencies
**Solution**: Enable Dependabot and review updates regularly

### Issue: Insecure Docker Configuration
**Solution**: Use official images and mount only necessary volumes

## Security Monitoring

- **GitHub Security tab**: View security alerts
- **Dependabot**: Automated dependency updates
- **Actions logs**: Monitor for security-related failures
- **Docker security**: Regular base image updates

For implementation details, see [Development Guide](Development-Guide).
