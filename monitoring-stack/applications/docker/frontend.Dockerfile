FROM node:18-alpine AS build
WORKDIR /app
COPY applications/frontend/package*.json ./
RUN npm install
COPY applications/frontend/ ./
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY applications/docker/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]