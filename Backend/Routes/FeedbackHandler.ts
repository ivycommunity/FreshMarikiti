import { IncomingMessage, ServerResponse } from "http";
import Users from "../Database/Users";
import Feedback, { type feedback } from "../Database/Feedback";

export const FeedbackRoute = (
  request: IncomingMessage,
  response: ServerResponse<IncomingMessage>
) => {
  let feedback: any = "";

  try {
    request.on("data", (data: Buffer) => {
      feedback += data.toString();
    });

    request.on("end", async () => {
      let parsedFeedback: feedback = JSON.parse(feedback);

      if (parsedFeedback) {
        if (!parsedFeedback.userid || !parsedFeedback.comment) {
          response.writeHead(409);
          response.end(
            "Incomplete credentials, ensure to pass in a user id for the person posting feedback and the feedback itself"
          );
          return;
        }

        const userFinder = await Users.findOne({ id: parsedFeedback.userid });

        if (!userFinder) {
          response.writeHead(404);
          response.end("User does not exist");
          return;
        }

        const insertion = await Feedback.insertOne({
          userid: parsedFeedback.userid,
          comment: parsedFeedback.comment,
        });

        if (insertion) {
          response.writeHead(201);
          response.end("Feedback has been added");
          return;
        }

        response.writeHead(500);
        response.end("Server error, failed to add feedback, please try again");
        return;
      }
    });
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
};
