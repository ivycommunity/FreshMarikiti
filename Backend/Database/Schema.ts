import * as mongoose from "mongoose";

const Schema = new mongoose.Schema({
  id: mongoose.SchemaTypes.String,
  name: mongoose.SchemaTypes.String,
  email: mongoose.SchemaTypes.String,
  password: mongoose.SchemaTypes.String,
});

export default mongoose.model("Users", Schema);
