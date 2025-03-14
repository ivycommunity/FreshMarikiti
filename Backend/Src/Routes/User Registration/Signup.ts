import { Request, Response, Router } from "express";
import { insertUser } from "../../Database/Database";
import { PostgrestError } from "@supabase/supabase-js";

type credentials = {
  name: string;
  email: string;
  password: string;
  role: "Admin" | "Vendor" | "Farmer";
};

export const SignupRoute: Router = Router();

SignupRoute.post("/", async (request: Request, response: Response) => {
  const { name, email, password, role }: credentials = request.body;
  if (!name || !email || !password || !role) {
    response
      .status(400)
      .send(
        "Fields are missing, please ensure request body has the fields; name,email,password and role with defined and valid values inside"
      );
  } else {
    if (name.length > 0 && email && password.length > 0 && role.length > 0) {
      let emailValidator =
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/.test(
          email
        );

      if (emailValidator) {
        const insertion = await insertUser({
          name: name,
          email: email,
          password: password,
          role: role,
        });

        if (insertion instanceof PostgrestError)
          response.status(400).send(response.json(insertion));
        else {
          if (insertion == "User already exists")
            response.status(400).send("User already exists");
          else response.status(202).send("User added");
        }
      } else response.status(400).send("Invalid email applied");
    } else
      response
        .status(400)
        .send(
          "Invalid credentials, all fields must be filled, check for any null values"
        );
  }
});
