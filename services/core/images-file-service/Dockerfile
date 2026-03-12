FROM nginx:alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# Create directory for assets
RUN mkdir -p /usr/share/nginx/html/assets/images

# Create logs directory
RUN mkdir -p /var/log/nginx

# Create 404.svg placeholder
RUN echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><text x="10" y="50" font-family="Arial" font-size="12">404 Not Found</text></svg>' > /usr/share/nginx/html/assets/images/404.svg

# Expose port
EXPOSE 5173

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
