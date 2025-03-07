import { Router, Request, Response } from "express";
import { updateUser } from "../../Database/Database";

type newCredentials = {
  id: number | undefined;
  name?: string | undefined;
  email?: string | undefined;
  password?: string | undefined;
  role?: string | undefined;
};

export const UpdateRoute: Router = Router();

UpdateRoute.patch(
  "/",
  async (request: Request, response: Response): Promise<void> => {
    try {
      if (request.body) {
        const details: newCredentials = request.body;

        if (details.id == undefined) {
          response
            .status(400)
            .send(
              "Invalid user ID provided, please provide a user ID for user identification"
            );
        } else {
          for (let [key, value] of Object.entries(details)) {
            if (value != undefined) {
              if (key == "email") {
                let emailValidator =
                  /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/.test(
                    value as string
                  );

                if (emailValidator) {
                  updateUser({
                    id: details.id,
                    email: value as string,
                  });
                  continue;
                } else {
                  response.status(400).send("Invalid email provided");
                }
              }
              if (key == "password") {
                if (value.toString().length > 3) {
                  updateUser({
                    id: details.id,
                    password: value as string,
                  });
                  continue;
                } else response.status(400).send("Password is too short");
              }
              updateUser({
                id: details.id,
                [key]: value,
              });
            }
          }
          response.status(201).send("Update successful");
        }
      } else response.status(404).send("Request body is empty/undefined");
    } catch (error) {
      throw error;
    }
  }
);
