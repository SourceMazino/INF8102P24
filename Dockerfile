# Use the official PHP image with Apache
FROM php:8.4-apache

# Set the working directory
WORKDIR /var/www/html

# Copy application files to the container
COPY . /var/www/html

# Set permissions for uploads directory
RUN mkdir -p uploads && \
    chown -R www-data:www-data uploads && \
    chmod -R 755 uploads

# Expose port 80 for the web server
EXPOSE 80

# Start the Apache server
CMD ["apache2-foreground"]
