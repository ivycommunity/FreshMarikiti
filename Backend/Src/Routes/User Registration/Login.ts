import express, { Request, Response, Router } from "express";
import { fetchUser } from "../../Database/Database";
import { PostgrestError } from "@supabase/supabase-js";

type credentials = {
  email: string;
  password: string;
};

export const LoginRoute: Router = express.Router();

LoginRoute.post(
  "/",
  async (request: Request, response: Response): Promise<void> => {
    if (request.body) {
      const { email, password }: credentials = request.body;

      if (email && password) {
        const request = await fetchUser({ email: email });

        if (!(request instanceof PostgrestError)) {
          const user = request.find((user) => user.Email == email);

          if (user) {
            if (user.Password == password)
              response.status(200).send("Login successful");
            else response.status(400).send("Invalid password");
          } else response.status(404).send("User not found");
        }
      } else
        response
          .status(400)
          .send(
            "Fields are missing, please ensure the fields; email and password are provided and filled with defined and valid values"
          );
    } else {
      response.status(404).send("Request body is empty");
    }
  }
);
