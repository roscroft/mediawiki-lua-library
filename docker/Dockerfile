FROM mediawiki:1.43.@sha256:2cfabe4c1de8d94b2f184a32cb9dfa8c106550f25ce3649f556434e1a3ef0451

# Update all system packages to their latest versions to reduce vulnerabilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends lua5.1 liblua5.1-0-dev git sqlite3 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Scribunto extension with specific location validation
RUN cd /var/www/html/extensions && \
    rm -rf Scribunto && \
    git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/Scribunto.git && \
    cd Scribunto && \
    git checkout REL1_39 && \
    echo "Verifying Scribunto installation:" && \
    ls -la /var/www/html/extensions/Scribunto && \
    find /var/www/html/extensions/Scribunto -name "*.php" | grep -q "Scribunto.php"

# Copy LocalSettings.php template (will be applied after DB installation)
COPY config/LocalSettings.template.php /var/www/html/config/LocalSettings.template.php

# Copy environment files and test scripts
COPY tests/env/wiki-lua-env.lua /var/www/html/wiki-lua-env.lua
COPY tests/env/module-loader.lua /var/www/html/module-loader.lua

# Copy testing scripts
COPY tests/php/test-script.php /var/www/html/test-script.php
COPY tests/php/test-script-simple.php /var/www/html/test-script-simple.php
RUN chmod +x /var/www/html/test-script.php /var/www/html/test-script-simple.php

# Create custom modules directory and copy module files
RUN mkdir -p /var/www/html/modules/custom
COPY build/modules/ /var/www/html/modules/custom/

# Copy entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
