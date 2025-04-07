import * as http from "http";
import * as mongoose from "mongoose";
import {
  Signup,
  Login,
  Update,
  Delete,
  googleAuthentication,
  googleUserToken,
  retrieveUser,
} from "./Routes/AccountCRUD";
import { Payment, Redirect } from "./M-Pesa/Setup";
import * as dotenv from "dotenv";
import {
  listProducts,
  addProduct,
  updateProduct,
  deleteProduct,
} from "./Routes/ProductsHandler";
import { Transact } from "./Routes/CurrencyHandler";

dotenv.config({
  path: "./.env",
});
//
const portNumber = process.env.PORT,
  mongoUri = process.env.MONGO_URI;

const server = http.createServer(
  async (
    request: http.IncomingMessage,
    response: http.ServerResponse<http.IncomingMessage>
  ) => {
    let url = new URL(request.url as string, `http://${request.headers.host}`),
      urlSegment = url.pathname.split("/").filter(Boolean);

    if (urlSegment[0] == "accounts") {
      switch (urlSegment[1]) {
        case "user":
          let userToken = request.headers["user-access-token"];

          if (userToken) {
            let user = await retrieveUser(userToken as string);

            if (user) response.end(JSON.stringify(user));
            else response.end("Access token expired, refresh");
          } else {
            response.writeHead(401, "Non-authentication");
            response.end(
              "Unauthenticated user, authenticate yourself first, required headers "
            );
          }
          break;
        case "login":
          if (request.method == "POST") Login(request, response);
          else {
            response.writeHead(405);
            response.end(
              "Invalid http method passed in for this route, pass in a POST method"
            );
          }
          break;
        case "signup":
          if (request.method == "POST") Signup(request, response);
          else {
            response.writeHead(405);
            response.end(
              "Invalid http method passed in for this route, pass in a POST method"
            );
          }
          break;
        case "googleoauth":
          googleAuthentication(response);
          break;
        case "googleredirect":
          googleUserToken(request, response);
          break;
        case "googlefail":
          response.end("Google Oauth rejected");
          break;
        case "update":
          if (request.method == "PUT") Update(request, response);
          else {
            response.writeHead(405);
            response.end("Update route, use a put method instead");
          }
          break;
        case "delete":
          if (request.method == "DELETE") Delete(request, response);
          else {
            response.writeHead(405);
            response.end("Invalid http method, try DELETE next time.");
          }
          break;
        default:
          response.writeHead(404, { location: "/user" });
          break;
      }
    } else if (urlSegment[0] == "payments") {
      switch (urlSegment[1]) {
        case "process":
          Payment(request, response);
          break;
        case "redirect":
          Redirect(request, response);
          break;
        default:
          response.writeHead(404, "Invalid Route");
          response.end("Route passed in does not exist");
          break;
      }
    } else if (urlSegment[0] == "products") {
      switch (urlSegment[1]) {
        case "list":
          listProducts(request, response);
          break;
        case "add":
          if (request.method == "POST") addProduct(request, response);
          else {
            response.writeHead(405);
            response.end("Invalid http method, use POST instead");
          }
          break;
        case "update":
          if (request.method == "PUT") updateProduct(request, response);
          else {
            response.writeHead(405);
            response.end("Invalid http method, use PUT instead");
          }
          break;
        case "delete":
          if (request.method == "DELETE") deleteProduct(request, response);
          else {
            response.writeHead(405);
            response.end("Invalid http method, use DELETE instead");
          }
          break;
        case "purchase":
          if (request.method == "POST") Transact(request, response);
          else {
            response.writeHead(405);
            response.end("Invalid http method, use DELETE instead");
          }
          break;
        default:
          response.writeHead(404, "Invalid Route");
          response.end("Route passed in does not exist");
          break;
      }
    } else {
      response.writeHead(200, {
        "content-type": "text/html",
      });
      response.end("Index route to Fresh Marikiti Application");
    }
  }
);

server.listen(portNumber, async () => {
  mongoose
    .connect(mongoUri as string, {
      dbName: "Marikiti",
      timeoutMS: 150000,
    })
    .then(() => {
      console.log(
        `Database connected, server is up and running at port ${portNumber}`
      );
    })
    .catch(() => {
      console.log(
        `Server is up and running at port ${portNumber}. Network failure on database, try again`
      );
    });
});

process.on("uncaughtException", (error) => {
  console.log(error);
});
process.on("unhandledRejection", (error) => {
  console.log(error);
});
