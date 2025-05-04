import mongoose, { Schema } from "mongoose";

interface OrderObj {
  orderid: string;
  buyerid: string;
  sellerid: string;
  productid: string;
  quantity: number;
  status: "Rejected" | "Pending" | "Complete";
}

const Orders = new Schema<OrderObj>({
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
  status: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
});

export default mongoose.model("Orders", Orders);
