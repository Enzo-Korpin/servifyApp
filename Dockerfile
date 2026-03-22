FROM node:20-alpine

WORKDIR /src/app

# Copy manifests
COPY package*.json ./

# Install ALL dependencies (including devDependencies like nodemon)
RUN npm install

# Copy source
COPY . .

# EXPOSE is documentation; ensures you know which port to map
EXPOSE 5000

# Default command
CMD ["node", "backend/server.js"]