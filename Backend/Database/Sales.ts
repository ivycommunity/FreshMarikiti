import * as mongoose from "mongoose";
import { Product } from "./Products";

type Sale = {
  sellerid: string;
  salesDone: number;
  Products: Product[];
  ProfitDone: number;
};
