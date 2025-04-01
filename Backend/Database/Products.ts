import mongoose from "mongoose";

interface Product {
  id: string;
  name: string;
  seller: string;
  sellerid: string;
  phonenumber: string;
  description?: string;
  image?: string;
  amount: number;
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
});

export default mongoose.model("Products", Schema);
