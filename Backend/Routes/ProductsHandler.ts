import { IncomingMessage, ServerResponse } from "http";
import Products from "../Database/Products";
import Users, { User } from "../Database/Users";
import { retrieveUser } from "./AccountCRUD";
import { type feedback } from "../Database/Feedback";
import * as crypto from "crypto";

type ProductUpdateBody = {
  sellerid: string;
  productid: string;
  name?: string;
  amount?: number;
  desc?: string;
  image?: string;
  quantity?: number;
  category?: string;
  comments?: feedback[];
};

export const verifyUser = async (
  accessToken: string
): Promise<string | User> => {
  let user: any = await retrieveUser(accessToken as string);

  if (typeof user !== "string") {
    let userFinder = await Users.findOne({ id: user.id });

    if (userFinder) return userFinder;
    else return "User doesn't exist in database";
  } else return "Token is either expired or non-existent";
};

export const listProducts = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user-token"];

    if (userToken) {
      let User = await verifyUser(userToken as string);

      if (typeof User !== "string") {
        let sellerProducts = await Products.find({ sellerid: User.id });
        response.writeHead(200);

        if (sellerProducts.length > 0)
          response.end(JSON.stringify(sellerProducts));
        else response.end("No products found");

        return;
      } else {
        switch (User) {
          case "User doesn't exist in database":
            response.writeHead(404);
            response.end("User does not exist in the database");
            break;
          default:
            response.writeHead(403);
            response.end("Token is non-existent, please login again");
            break;
        }
      }
    } else {
      response.writeHead(401);
      response.end("Unauthenticated user, authenticate yourself first");
      return;
    }
  },
  addProduct = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user-token"];

    if (userToken) {
      let User = await verifyUser(userToken as string);

      if (typeof User !== "string") {
        let itemInfo: any = "";

        request.on("data", (item: Buffer) => {
          itemInfo += item.toString();
        });
        request.on("end", async () => {
          try {
            itemInfo = JSON.parse(itemInfo);

            if (typeof itemInfo !== "string") {
              if (
                !itemInfo.name ||
                !itemInfo.sellerid ||
                !itemInfo.seller ||
                !itemInfo.phonenumber ||
                !itemInfo.quantity ||
                !itemInfo.amount
              ) {
                response.writeHead(405);
                response.end(
                  "Incomplete body content, ensure to provide i.e. name, seller ID, seller, phonenumber, amount and quantity of the product required"
                );
              } else {
                try {
                  await Products.insertOne({
                    id: crypto.randomBytes(16).toString("hex"),
                    name: itemInfo.name,
                    description: itemInfo.desc ? itemInfo.desc : "",
                    sellerid: itemInfo.sellerid,
                    seller: itemInfo.seller,
                    phonenumber: itemInfo.phonenumber,
                    image: itemInfo.image ? itemInfo.image : "",
                    quantity: itemInfo.quantity,
                    amount: itemInfo.amount,
                  });
                  response.writeHead(201);
                  response.end("Product added");
                  return;
                } catch (error) {
                  response.writeHead(500);
                  response.end("Server error, please try again");
                  return;
                }
              }
            }
          } catch (error) {
            response.writeHead(500);
            response.write("Server error, please try again");
          }
        });
      } else {
        switch (User) {
          case "User doesn't exist in database":
            response.writeHead(404);
            response.end("User does not exist in the database");
            break;
          default:
            response.writeHead(403);
            response.end("Token is non-existent, please login again");
            break;
        }
      }
    } else {
      response.writeHead(401);
      response.end("Unauthenticated user, authenticate yourself first");
      return;
    }
  },
  updateProduct = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    try {
      let userToken = request.headers["user-token"];

      if (userToken) {
        let User = await verifyUser(userToken as string);

        if (typeof User !== "string") {
          let Data: any = "";

          request.on("data", (item: Buffer) => {
            Data += item.toString();
          });
          request.on("end", async () => {
            let itemData: ProductUpdateBody = JSON.parse(Data);

            if (User.id == itemData.sellerid) {
              if (!itemData.productid || !itemData.sellerid) {
                response.writeHead(405);
                response.end(
                  "Ensure to insert product id and seller id are present in the request body"
                );
              } else {
                for (let [key, value] of Object.entries(itemData).map(
                  (_, index, array) => [
                    array[index][0].toString().toLowerCase(),
                    array[index][1],
                  ]
                )) {
                  if (key == "name") {
                    if ((value as string).length <= 0) {
                      response.end(
                        "Ensure product name has a value not an empty string"
                      );
                      return;
                    }
                    await Products.findOneAndUpdate(
                      { id: itemData.productid },
                      { name: value }
                    );
                  } else if (key == "amount") {
                    if (typeof value != "number") {
                      response.writeHead(500);
                      response.end(
                        "Invalid type, pass in a number for product"
                      );
                      return;
                    }
                    await Products.findOneAndUpdate(
                      { id: itemData.productid },
                      { amount: value }
                    );
                  } else if (key == "desc") {
                    if ((value as string).length <= 0) {
                      response.end(
                        "Ensure a description is provided not an empty string"
                      );
                    }
                    await Products.findOneAndUpdate(
                      { id: itemData.productid },
                      { description: value }
                    );
                  } else if (key == "image") {
                    if ((value as string).length <= 0) {
                      response.end(
                        "Ensure image is provided with a valid source"
                      );
                      return;
                    }
                    await Products.findOneAndUpdate(
                      { id: itemData.productid },
                      { image: value }
                    );
                  } else if (key == "quantity") {
                    if ((value as number) < 0) {
                      response.end("Invalid quantity, should be 0 or greater");
                      return;
                    }
                    await Products.findOneAndUpdate(
                      { id: itemData.productid },
                      { quantity: value }
                    );
                  } else if (key == "category") {
                    if (typeof value == "string" && value.length > 0) {
                      await Products.findOneAndUpdate(
                        {
                          id: itemData.productid,
                        },
                        {
                          category: value,
                        }
                      );
                    }
                  } else if (key == "comments") {
                    if (Array.isArray(value)) {
                      let comments: feedback[] = [];

                      value.forEach((Comment: feedback) => {
                        if (Comment.userid && Comment.comment) {
                          comments.push(Comment);
                        }
                      });

                      await Products.findOneAndUpdate(
                        { id: itemData.productid },
                        {
                          comments: comments,
                        }
                      );
                    }
                  } else continue;
                }
                response.writeHead(201);
                response.end("Update successful");
                return;
              }
            } else {
              response.writeHead(403);
              response.end("User does not own such as item");
              return;
            }
          });
        } else {
          switch (User) {
            case "User doesn't exist in database":
              response.writeHead(404);
              response.end("User does not exist in the database");
              break;
            default:
              response.writeHead(403);
              response.end("Token is non-existent, please login again");
              break;
          }
        }
      } else {
        response.writeHead(401);
        response.end("Authenticate yourself, pass in a token header");
      }
    } catch (error) {
      if (error instanceof SyntaxError) {
        response.writeHead(405);
        response.end("Invalid json format, send in a valid json format");
      }
      response.writeHead(500);
      response.end(error);
    }
  },
  deleteProduct = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user-token"];

    if (userToken) {
      let User = await verifyUser(userToken as string);

      if (typeof User !== "string") {
        let itemInfo: any = "";

        request.on("data", (item: Buffer) => {
          itemInfo += item.toString();
        });

        request.on("close", async () => {
          try {
            itemInfo = JSON.parse(itemInfo);
            if (User.id == itemInfo.sellerid) {
              if (!itemInfo.productid || !itemInfo.sellerid) {
                response.writeHead(409);
                response.end(
                  "Incomplete credentials passed in, pass in the product id and seller id to continue"
                );
              } else {
                let deletion = await Products.findOneAndDelete({
                  id: itemInfo.productid,
                  sellerid: itemInfo.sellerid,
                });

                if (deletion) {
                  response.writeHead(204);
                  response.end("Successful deletion");
                  return;
                } else {
                  response.writeHead(500);
                  response.end("Database error, please try again later");
                  return;
                }
              }
            } else {
              response.writeHead(403);
              response.end("User does not have such an item in inventory");
            }
          } catch (error) {
            if (error instanceof SyntaxError) {
              response.writeHead(409);
              response.end(
                "Invalid JSON format, pass in a valid format JSON body"
              );
            }
          }
        });
      } else {
        switch (User) {
          case "User doesn't exist in database":
            response.writeHead(404);
            response.end("User does not exist in the database");
            break;
          default:
            response.writeHead(403);
            response.end("Token is non-existent, please login again");
            break;
        }
      }
    }
  };
