FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

COPY . .

RUN npm ci

EXPOSE 3000

CMD [ "node","Index.js" ]