import { retrieveUser } from "./AccountCRUD";
import Users from "../Database/Users";
import { IncomingMessage, ServerResponse } from "http";
import { Server, Socket } from "socket.io";
import Products from "../Database/Products";
import Order from "../Database/Order";
import * as crypto from "crypto";
import * as JWT from "jsonwebtoken";
import { sendNotification } from "./NofiticationsHandler";
import { createSemanticDiagnosticsBuilderProgram } from "typescript";

export type Transacters = {
  buyerid: string;
  sellerid: string;
  productid: string;
  quantity: number;
};
type Transactions = {
  Transactions: Transacters[] | Transacters;
};

//Update funds --> Adds bioCoins
//Transact --> Used between bioCoins

let accessToken = process.env.JWT_ACCESS_TOKEN,
  orderEncoder = ({
    orderId,
    buyerId,
    sellerId,
    productId,
    quantity,
    status,
  }: {
    orderId: string;
    buyerId: string;
    sellerId: string;
    productId: string;
    quantity: number;
    status: string;
  }): string | Error => {
    if (!orderId || !buyerId || !sellerId || !productId || !quantity)
      return new Error("Incomplete credentials");
    else {
      let orderToken = JWT.sign(
        {
          orderId: orderId,
          buyerId: buyerId,
          sellerId: sellerId,
          productId: productId,
          quantity: quantity,
          status: status,
        },
        accessToken as string
      );
      return orderToken;
    }
  };

export const updateFunds = async (
    userId: string,
    amount: number
  ): Promise<string | Error> => {
    try {
      if (userId && amount) {
        let user = await retrieveUser(userId);

        if (typeof user !== "string") {
          let userFinder = await Users.findOne({ id: user.id });

          if (userFinder) {
            await Users.findOneAndUpdate(
              { id: userFinder.id },
              { biocoins: userFinder.biocoins + amount }
            );
            return "Successful update";
          } else return "User does not exist in the database";
        } else return "Non-existent user";
      } else return "Incomplete credentials";
    } catch (error) {
      return error as Error;
    }
  },
  InitiateOrder = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>,
    io: Server
  ) => {
    try {
      let Transactions: any;

      request.on("data", (transactionData: Buffer) => {
        Transactions = transactionData.toString();
      });
      request.on("end", async () => {
        let transactions: Transacters | Transacters[] =
          JSON.parse(Transactions);

        if (Array.isArray(transactions)) {
          let orderTokens: string[] = [];

          transactions.forEach(async (transaction) => {
            let orderId = crypto.randomBytes(10).toString("hex"),
              orderToken = orderEncoder({
                orderId: orderId,
                productId: transaction.productid,
                sellerId: transaction.sellerid,
                quantity: transaction.quantity,
                buyerId: transaction.buyerid,
                status: "Pending",
              });

            if (typeof orderToken == "string") orderTokens.push(orderToken);
            else {
              response.writeHead(500, "Order tokens failed, please try again");
              response.end();
              return;
            }

            await Order.insertOne({
              orderid: orderId,
              buyerid: transaction.buyerid,
              sellerid: transaction.sellerid,
              quantity: transaction.quantity,
              status: "Pending",
            });
          });

          response.writeHead(
            200,
            "Order tokens appear in the same order as passed in from the request body"
          );
          response.end(orderTokens);
        } else {
          let orderId = crypto.randomBytes(10).toString("hex"),
            Buyer = await Users.findOne({ id: transactions.buyerid }),
            Seller = await Products.findOne({ id: transactions.productid }),
            Product = await Products.findOne({ id: transactions.productid }),
            orderToken = orderEncoder({
              orderId: orderId,
              productId: transactions.productid,
              buyerId: transactions.buyerid,
              sellerId: transactions.sellerid,
              quantity: transactions.quantity,
              status: "Pending",
            });

          await Order.insertOne({
            orderid: orderId,
            productid: transactions.productid,
            buyerid: transactions.buyerid,
            sellerid: transactions.sellerid,
            quantity: transactions.quantity,
            status: "Pending",
          });

          if (Buyer && Seller && Product)
            io.to(Buyer.name).emit("Transaction Initiated", {
              Seller: Seller.name,
              Product: Product.name,
            });
          else {
            response.writeHead(
              404,
              "Product, seller or buyer id is invalid, check again please"
            );
            response.end();
          }

          response.writeHead(200, "Order initiated and stored");
          response.end(orderToken);
        }
      });
    } catch (error) {
      if (
        error instanceof Error &&
        (error.name.includes("Syntax") || error.message.includes("Syntax"))
      ) {
        response.writeHead(409);
        response.end("Incorrect JSON format");
        return;
      }
      response.writeHead(500);
      response.end("Server error, please try again");
      return;
    }
  },
  UpdateOrder = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user-token"];

    if (userToken) {
      let User = await retrieveUser(userToken as string);

      if (typeof User !== "string") {
        try {
          let orderBody: any = "";

          request.on("data", (data: Buffer) => {
            orderBody += data.toString();
          });
          request.on("end", async () => {
            let orderObj: { orderId: string; status: "accepted" | "rejected" } =
              JSON.parse(orderBody);

            if (orderObj.orderId && orderObj.status) {
              let orderFinder = await Order.findOne({
                orderid: orderObj.orderId,
              });
              if (orderFinder) {
                if (orderObj.status == "accepted") {
                  orderFinder.updateOne({ status: "Accepted" });

                  let Buyer = await Users.findOne({ id: orderFinder.buyerid }),
                    Seller = await Users.findOne({ id: orderFinder.sellerid }),
                    Product = await Products.findOne({
                      id: orderFinder.productid,
                    });

                  if (Buyer && Seller && Product) {
                    if (Product.quantity < orderFinder.quantity) {
                      response.writeHead(
                        409,
                        "Quantity demanded is insufficient to what is provided"
                      );
                      response.end();
                      return;
                    }

                    if (
                      Buyer.biocoins >=
                      orderFinder.quantity * Product.amount
                    ) {
                      await Buyer.updateOne({
                        biocoins:
                          Buyer.biocoins -
                          orderFinder.quantity * Product.amount,
                      });

                      await Seller.updateOne({
                        biocoins:
                          Buyer.biocoins +
                          orderFinder.quantity * Product.amount,
                      });

                      await Product.updateOne({
                        quantity: Product.quantity - orderFinder.quantity,
                      });

                      await Order.deleteOne({ id: orderFinder.id });

                      if (Product.quantity < 5)
                        sendNotification({
                          title: "Stock deficit",
                          body: `Your stock of ${Product.name} is at ${Product.quantity}`,
                          token: "",
                        });

                      response.writeHead(200, "Transaction successful");
                      response.end();
                    } else {
                      response.writeHead(405, "Insufficient funds");
                      response.end();
                    }
                  } else {
                    response.writeHead(
                      404,
                      "Buyer, seller or product id is invalid check again"
                    );
                    response.end();
                    return;
                  }
                } else {
                  response.writeHead(200, "Order rejected.");
                  response.end();
                }

                await Order.findOneAndDelete({ id: orderObj.orderId });
                return;
              } else {
                response.writeHead(404, "Order not found, id is not existing");
                response.end();
                return;
              }
            } else {
              response.writeHead(409, "Order id and status required");
              response.end();
              return;
            }
          });
        } catch (error) {
          if (
            error instanceof Error &&
            (error.message.includes("Syntax") || error.name.includes("Syntax"))
          ) {
            response.writeHead(409, "Invalid JSON parsed in");
            response.end("");
            return;
          }
        }
      } else {
        response.writeHead(
          403,
          "Non-existent user, token expired or non-existent"
        );
        response.end();
        return;
      }
    } else {
      response.writeHead(
        401,
        "Unauthenticate yourself, authenticate yourself."
      );
      response.end();
      return;
    }
  };
