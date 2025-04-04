import { retrieveUser } from "./AccountCRUD";
import Users from "../Database/Users";
import { IncomingMessage, ServerResponse } from "http";
import { verifyUser } from "./ProductsHandler";
import Products from "../Database/Products";

type Transacters = {
  buyerid: string;
  sellerid: string;
  productid: string;
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
            global.User = null;
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
        let transacters: Transacters = JSON.parse(transaction);

        if (
          transacters.buyerid &&
          transacters.sellerid &&
          transacters.productid
        ) {
          let productFinder = await Products.findOne({
              id: transacters.productid,
            }),
            buyer = await Users.findOne({ id: transacters.buyerid }),
            seller = await Users.findOne({ id: transacters.sellerid });

          if (productFinder) {
            if (buyer && seller) {
              if (buyer.biocoins < productFinder.amount) {
                response.writeHead(402);
                response.end();
              } else {
                await buyer.updateOne({
                  biocoins: buyer.biocoins - productFinder.amount,
                });
                await seller.updateOne({
                  biocoins: seller.biocoins + productFinder.amount,
                });
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
        }
      });
    }
  };
