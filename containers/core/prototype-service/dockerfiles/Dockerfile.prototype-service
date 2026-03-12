FROM nginx:alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# Create logs directory
RUN mkdir -p /var/log/nginx

# Expose port
EXPOSE 9630

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
