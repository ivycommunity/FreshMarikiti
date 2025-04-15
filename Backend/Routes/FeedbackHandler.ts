import { IncomingMessage, ServerResponse } from "http";
import Users from "../Database/Users";
import Feedback, { type feedback } from "../Database/Feedback";
import { verifyUser } from "./ProductsHandler";

export const FeedbackRoute = async (
  request: IncomingMessage,
  response: ServerResponse<IncomingMessage>
) => {
  let feedback: any = "",
    userToken: any = request.headers["user-token"];

  if (userToken) {
    try {
      let user = await verifyUser(userToken);
      if (typeof user !== "string") {
        request.on("data", (data: Buffer) => {
          feedback += data.toString();
        });
        request.on("end", async () => {
          let parsedFeedback: feedback = JSON.parse(feedback);

          if (parsedFeedback) {
            if (!parsedFeedback.comment || !parsedFeedback.category) {
              response.writeHead(409);
              response.end(
                "Incomplete credentials, ensure to pass in a user id for the person posting feedback and the feedback itself"
              );
              return;
            }

            const userFinder = await Users.findOne({
              id: user.id,
            });

            if (!userFinder) {
              response.writeHead(404);
              response.end("User does not exist");
              return;
            }

            const insertion = await Feedback.insertOne({
              userid: user.id,
              comment: parsedFeedback.comment,
              category: parsedFeedback.category,
            });

            if (insertion) {
              response.writeHead(201);
              response.end("Feedback has been added");
              return;
            }

            response.writeHead(500);
            response.end(
              "Server error, failed to add feedback, please try again"
            );
            return;
          } else {
            response.writeHead(409);
            return response.end("Invalid feedback passed in");
          }
        });
      } else {
        response.writeHead(403);
        return response.end("Expired token passed in, log in again please");
      }
    } catch (error) {
      if (
        (error as Error).name.includes("Syntax error") ||
        (error as Error).message.includes("JSON")
      ) {
        response.writeHead(409);
        response.end("Invalid json passed in, ensure json is valid");
      } else {
        response.writeHead(500);
        response.end("Server failure please try again");
      }
    }
  } else {
    response.writeHead(409);
    response.end("Provide user token for identification");
  }
};
