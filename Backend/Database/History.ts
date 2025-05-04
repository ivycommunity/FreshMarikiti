import mongoose, { Schema } from "mongoose";
import { type OrderObj } from "./Order";

type OrderHistory = Omit<OrderObj, "status"> & {
  status: "Rejected" | "Complete";
};

const TransactionHistory = new Schema<OrderHistory>({
  orderid: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  buyerid: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  sellerid: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  productid: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  quantity: {
    type: mongoose.SchemaTypes.Number,
    required: true,
  },
  status: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
});
