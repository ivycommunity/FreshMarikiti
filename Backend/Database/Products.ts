import mongoose from "mongoose";
import { Middleware } from "./Middleware";

export interface Product {
  id: string;
  name: string;
  seller: string;
  sellerid: string;
  phonenumber: string;
  description?: string;
  quantity: number;
  image?: string;
  amount: number;
  category: string;
}

const Schema = new mongoose.Schema<Product>({
  id: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  name: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  seller: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  sellerid: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  quantity: {
    type: mongoose.SchemaTypes.Number,
    required: true,
  },
  phonenumber: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  description: {
    type: mongoose.SchemaTypes.String,
    required: false,
  },
  image: {
    type: mongoose.SchemaTypes.String,
    required: false,
  },
  amount: {
    type: mongoose.SchemaTypes.Number,
    required: true,
  },
  category: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
});

Middleware(Schema);

export default mongoose.model("Products", Schema);
