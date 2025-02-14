# Use Debian 11 as the base image
FROM php:8.2-apache

# Set environment variables
ENV DB_NAME=wordpress_db
ENV DB_USER=wordpress_user
ENV DB_PASSWORD=mypassword
ENV DB_HOST=10.184.49.241 
ENV APACHE_ROOT=/var/www/html/wordpress/

# Set timezone and install dependencies
RUN apt-get update && \
    apt-get install -y \
    nano \
    rsync \
    software-properties-common \
    mariadb-client \
    git \
    sudo \
    curl \
    php8.2-cli \
    php8.2-common \
    php8.2-mysqli \
    php8.2-redis \
    php8.2-snmp \
    php8.2-xml \
    php8.2-zip \
    php8.2-mbstring \
    php8.2-curl \
    libapache2-mod-php \
    lsb-release && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module
RUN a2enmod rewrite

# Clone WordPress repository
RUN rm -rf ${APACHE_ROOT} && \
    mkdir -p ${APACHE_ROOT} && \
    git clone --depth=1 --branch main https://github.com/NarpaviGomathi/WordPress.git ${APACHE_ROOT} && \
    chown -R www-data:www-data ${APACHE_ROOT} && \
    find ${APACHE_ROOT} -type d -exec chmod 755 {} \; && \
    find ${APACHE_ROOT} -type f -exec chmod 644 {} \;
RUN chmod -R 755  ${APACHE_ROOT}
RUN chown -R www-data:www-data ${APACHE_ROOT} 

# Configure WordPress wp-config.php
RUN mv ${APACHE_ROOT}/wp-config-sample.php ${APACHE_ROOT}/wp-config.php && \
    sed -i "s/database_name_here/${DB_NAME}/" ${APACHE_ROOT}/wp-config.php && \
    sed -i "s/username_here/${DB_USER}/" ${APACHE_ROOT}/wp-config.php && \
    sed -i "s/password_here/${DB_PASSWORD}/" ${APACHE_ROOT}/wp-config.php && \
    sed -i "s/localhost/${DB_HOST}/" ${APACHE_ROOT}/wp-config.php && \
    echo "define( 'FS_METHOD', 'direct' );" >> ${APACHE_ROOT}/wp-config.php && \
    sed -i "s/^\$table_prefix = .*/\$table_prefix = 'wp_';/" ${APACHE_ROOT}/wp-config.php

# Configure Apache Virtual Host
RUN echo "ServerName 10.184.49.241" >> /etc/apache2/apache2.conf && \
    echo '<VirtualHost *:80>' > /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    ServerName 10.184.49.241' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    ServerAlias 10.184.49.241' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    DocumentRoot /var/www/html/wordpress' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    <Directory "/var/www/html/wordpress">' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/wordpress.com-error.log' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/wordpress.com-access.log combined' >> /etc/apache2/sites-available/wordpress.com.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/wordpress.com.conf

# Enable Apache site and modules
RUN a2ensite wordpress.com.conf && \
    a2enmod rewrite

# Remove cache and old build data
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose port 80
EXPOSE 80


CMD service mariadb start && apachectl -D FOREGROUND

# Start Apache in the foreground
#CMD ["apache2ctl", "-D", "FOREGROUND"]
