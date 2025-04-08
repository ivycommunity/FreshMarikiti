import { retrieveUser } from "./AccountCRUD";
import Users from "../Database/Users";
import { IncomingMessage, ServerResponse } from "http";
import { verifyUser } from "./ProductsHandler";
import Products from "../Database/Products";

export type Transacters = {
  buyerid: string;
  sellerid: string;
  productid: string;
};
type Transactions = {
  Transactions: Transacters[];
};

//Update funds --> Adds bioCoins
//Transact --> Used between bioCoins

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
  Transact = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user-token"],
      user = verifyUser(userToken as string),
      transaction: any = "";

    if (typeof user !== "string") {
      request.on("data", (data: Buffer) => {
        transaction += data.toString();
      });
      request.on("end", async () => {
        let transacters: Transactions = JSON.parse(transaction);

        if (transacters && transacters.Transactions.length > 0) {
          transacters.Transactions.forEach(async (Transaction) => {
            try {
              let productFinder = await Products.findOne({
                  id: Transaction.productid,
                }),
                buyer = await Users.findOne({ id: Transaction.buyerid }),
                seller = await Users.findOne({ id: Transaction.sellerid });

              if (productFinder) {
                if (buyer && seller) {
                  if (productFinder.sellerid == seller.id) {
                    if (buyer.id != seller.id) {
                      if (buyer.biocoins < productFinder.amount) {
                        response.writeHead(402);
                        response.end("Buyer has insufficient funds");
                      } else {
                        await buyer.updateOne({
                          biocoins: buyer.biocoins - productFinder.amount,
                        });
                        await seller.updateOne({
                          biocoins: seller.biocoins + productFinder.amount,
                        });
                        response.writeHead(200);
                        response.end("Purchase successful");
                      }
                    } else {
                      response.writeHead(409);
                      response.end("Seller cannot sell to himself lollol😂");
                    }
                  } else {
                    response.writeHead(409);
                    response.end("Seller does not have such a product in sale");
                  }
                } else {
                  response.writeHead(404);
                  response.end("No such user exists");
                  return;
                }
              } else {
                response.writeHead(404);
                response.end("No such product exists");
                return;
              }
            } catch (error: any) {
              if (
                (error as Error).message.includes("timed out") ||
                (error as Error).name.includes("timed out")
              ) {
                response.writeHead(500);
                response.end("Database connection timed out please try again");
              }
            }
          });
        }
      });
    } else {
      response.writeHead(403);
      response.end("Unauthorized user, authenticate yourself");
    }
  };
