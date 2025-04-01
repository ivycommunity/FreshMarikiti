import dotenv from "dotenv";
import express, { Express, Request, Response } from "express";

dotenv.config();

import { LoginRoute } from "./Routes/User Registration/Login";
import { SignupRoute } from "./Routes/User Registration/Signup";
import { UpdateRoute } from "./Routes/User Registration/Update";
import { DeleteRoute } from "./Routes/User Registration/Delete";

const app: Express = express(),
  port: string = process.env.PORT as string;

//Middleware
app.use(express.json());

app.get("/", (_: Request, response: Response) => {
  response.status(200).send("Fresh Mirikiti backend setup");
});

//Routes
app.use("/login", LoginRoute);
app.use("/signup", SignupRoute);
app.use("/update", UpdateRoute);
app.use("/delete", DeleteRoute);

app.listen(port, () => {
  console.log("Server is running on port " + port);
});
