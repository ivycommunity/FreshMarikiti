import { Schema } from "mongoose";

export const Middleware = (schema: Schema) => {
  schema.post(/find/, (error: Error, response: any, next: Function) => {
    if (
      error.name == "MongoNetworkTimeoutError" ||
      error.message.includes("timed out")
    ) {
      return next(new Error("Database timed out please try again"));
    }
    return next(error);
  });
  schema.post(/update/, (error: Error, response: any, next: Function) => {
    if (
      error.name == "MongoNetworkTimeoutError" ||
      error.message.includes("timed out")
    ) {
      return next(new Error("Database timed out please try again"));
    }
    return next(error);
  });
  schema.post(/delete/, (error: Error, response: any, next: Function) => {
    if (
      error.name == "MongoNetworkTimeoutError" ||
      error.message.includes("timed out")
    ) {
      return next(new Error("Database timed out please try again"));
    }
    return next(error);
  });
  schema.post(/insert/, (error: Error, response: any, next: Function) => {
    if (
      error.name == "MongoNetworkTimeoutError" ||
      error.message.includes("timed out")
    ) {
      return next(new Error("Database timed out please try again"));
    }
    return next(error);
  });
};
