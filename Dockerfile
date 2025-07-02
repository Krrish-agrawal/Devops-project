
FROM node:lts-slim

WORKDIR /app
COPY . .


RUN cd Server && npm install --production

RUN cd Client && npm install && npm run build

# Set env for Express to find React static files
ENV CLIENT_BUILD_PATH=/app/Client/build


CMD ["node", "Server/index.js"]
