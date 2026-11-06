# ---- Stage 1: build the Angular app ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- Stage 2: serve it with Nginx ----
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/pipeline-demo/browser /usr/share/nginx/html
COPY deploy-config/dev.json /usr/share/nginx/html/config.json
