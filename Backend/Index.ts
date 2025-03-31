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
import { Payment } from "./M-Pesa/Setup";
import * as dotenv from "dotenv";

dotenv.config({
  path: "./.env",
});

const server = http.createServer(
  (
    request: http.IncomingMessage,
    response: http.ServerResponse<http.IncomingMessage>
  ) => {
    let url = new URL(request.url as string, `http://${request.headers.host}`),
      urlSegment = url.pathname.split("/").filter(Boolean);

    if (urlSegment[0] == "accounts") {
      switch (urlSegment[1]) {
        case "user":
          let token = request.headers["user_token"];

          if (token) {
            let user = retrieveUser(token as string);

            if (user) response.end(JSON.stringify(user));
            else response.end("Access token expired, refresh");
          } else
            response.end(
              "Unauthenticated user, authenticate yourself first, required headers "
            );
          break;
        case "login":
          if (request.method == "POST") Login(request, response);
          else
            response.end(
              "Invalid http method passed in for this route, pass in a POST method"
            );
          break;
        case "signup":
          if (request.method == "POST") Signup(request, response);
          else
            response.end(
              "Invalid http method passed in for this route, pass in a POST method"
            );
          break;
        case "googleoauth":
          googleAuthentication(response);
          break;
        case "googleredirect":
          googleUserToken(request, response);
          break;
        case "googlefail":
          response.end("Google Oauth failed");
          break;
        case "update":
          Update(request, response);
          break;
        case "delete":
          Delete(request, response);
          break;
        default:
          response.writeHead(404, { location: "/user" });
          break;
      }
    } else if (urlSegment[0] == "payments") {
      switch (urlSegment[2]) {
        case "process":
          Payment(request, response);
          break;
        case "redirect":
          console.log("Called in payment successful");
          response.end("Payment request successful");
          break;
        case "timeout":
          console.log("Called in timeout");
          response.end("Payment request timed out");
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

server.listen(process.env.PORT, () => {
  mongoose
    .connect(process.env.MONGO_URI as string)
    .then(() => {
      console.log(
        `Database connected, server is up and running at port ${process.env.PORT}`
      );
    })
    .catch(() => {
      console.log(
        `Server is up and running at port ${process.env.PORT}, database is down at the moment`
      );
    });
});
server.on("Closed", (error: Error) => {
  console.log(error);
  server.close();
});

process.on("uncaughtException", (error) => {
  server.emit("Closed", error);
});
process.on("unhandledRejection", (error) => {
  server.emit("Closed", error);
});
