import { Router, Request, Response } from "express";
import { deleteUser } from "../../Database/Database";
import { PostgrestError } from "@supabase/supabase-js";

export const DeleteRoute: Router = Router();

DeleteRoute.delete(
  "/",
  async (request: Request, response: Response): Promise<void> => {
    try {
      if (request.body) {
        const { email }: { email: string } = request.body;

        if (!email) response.status(404).send("Email field not provided");
        else {
          if (email.toString().length > 0) {
            const deleteQuery = await deleteUser({ email: email });

            if (!(deleteQuery instanceof PostgrestError))
              if (deleteQuery == "User doesn't exist")
                response.status(404).send("User not found in the database");
              else response.status(204).send("Deletion successful");
          }
        }
      } else response.status(400).send("Undefined request body");
    } catch (error) {
      throw error;
    }
  }
);
