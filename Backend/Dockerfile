FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

COPY . .

RUN npm ci \ && npm run dev

EXPOSE 3000

CMD [ "server" ]