import * as mongoose from "mongoose";
import { Middleware } from "./Middleware";

export type Product = {
  productid: string;
  imageSource: string;
  name: string;
  category: string;
  quantity: string;
  stock: number;
};

export interface User {
  id: string;
  name: string;
  email: string;
  password?: string;
  google: boolean;
  goals?: string;
  biocoins: number;
  cart: Product[];
}

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
  google: {
    type: mongoose.SchemaTypes.Boolean,
    required: true,
  },
  cart: {
    type: mongoose.SchemaTypes.Mixed,
    required: true,
  },
});

Middleware(Schema);

export default mongoose.model("Users", Schema);
