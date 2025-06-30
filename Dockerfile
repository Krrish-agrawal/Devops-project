# Base image
FROM node:lts-slim

# Set working directory
WORKDIR /app

# Copy all required files
COPY . .

# Install server dependencies
RUN cd Server && npm install --production

# Build React client
RUN cd Client && npm install && npm run build

# Set env for Express to find React static files
ENV CLIENT_BUILD_PATH=/app/Client/build

# Expose the port used by the backend
EXPOSE 5000

# Start the backend server
CMD ["node", "Server/index.js"]
