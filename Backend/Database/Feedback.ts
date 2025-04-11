import mongoose from "mongoose";
import { Middleware } from "./Middleware";

export interface feedback {
  userid: string;
  comment: string;
}

const Feedback = new mongoose.Schema<feedback>({
  userid: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  comment: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
});

Middleware(Feedback);

export default mongoose.model("Feedback", Feedback);
