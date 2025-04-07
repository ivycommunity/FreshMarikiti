import * as mongoose from "mongoose";

export interface User {
  id: string;
  name: string;
  email: string;
  password?: string;
  goals?: string;
  biocoins: number;
}
console.log("hello wold");
const Schema = new mongoose.Schema<User>({
  id: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  name: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  email: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  password: {
    type: mongoose.SchemaTypes.String,
    required: false,
  },
  biocoins: {
    type: mongoose.SchemaTypes.Number,
    required: true,
  },
});

export default mongoose.model("Users", Schema);
