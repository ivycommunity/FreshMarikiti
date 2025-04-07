import { retrieveUser } from "../Routes/AccountCRUD";
import { updateFunds } from "../Routes/CurrencyHandler";
import { IncomingMessage, ServerResponse } from "http";
import * as dotenv from "dotenv";
import * as https from "https";

dotenv.config({
  path: "./.env",
});

type TokenData = {
  access_token: string;
  expires_in: string;
};
type ItemData = {
  Name: string;
  Value: number;
};
type PaymentResponse = {
  Body: {
    stkCallback: {
      MerchantRequestID: string;
      CheckoutRequestID: string;
      ResultCode: number | string;
      ResultDesc: string;
      CallbackMetadata: {
        Item: ItemData[];
      };
    };
  };
};

console.log("Minor changes");

const consumerKey = process.env.MPESA_CKEY,
  consumerSecret = process.env.MPESA_CSECRET,
  passKey = process.env.MPESA_PASSKEY,
  shortCode = process.env.MPESA_SHORTCODE,
  callbackURL = process.env.MPESA_CALLBACKURL;

const Token = async (): Promise<any | Error> => {
    return new Promise((resolve, reject) => {
      let returnToken: any = "",
        basicAuthToken = Buffer.from(
          `${consumerKey}:${consumerSecret}`
        ).toString("base64"),
        requestToken = https.request(
          "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
          {
            method: "GET",
            headers: {
              authorization: `Basic ${basicAuthToken}`,
            },
          },
          (response: IncomingMessage) => {
            response.on("data", (token: Buffer) => {
              returnToken += token.toString();
            });
            response.on("error", (error) => {
              reject(error);
            });
          }
        );

      requestToken.on("error", (error) => {
        reject(error);
      });
      requestToken.on(
        "end",
        () => (returnToken = JSON.parse(JSON.stringify(returnToken)))
      );
      requestToken.on("close", () => {
        returnToken && resolve(returnToken);
      });

      requestToken.end();
    });
  },
  makePayment = async (
    phoneNumber: string,
    amount: number
  ): Promise<any | Error> => {
    const phonenumber = phoneNumber.includes("254")
        ? phoneNumber
        : "254" + phoneNumber.slice(1),
      token = await Token(),
      currentDate = new Date(),
      timeStamp =
        currentDate.getFullYear() +
        "" +
        (currentDate.getMonth() + 1 < 10
          ? (currentDate.getMonth() + 1).toString().padStart(2, "0")
          : currentDate.getMonth() + 1) +
        "" +
        (currentDate.getDate() < 10
          ? currentDate.getDate().toString().padStart(2, "0")
          : currentDate.getDate()) +
        "" +
        (currentDate.getHours() < 10
          ? currentDate.getHours().toString().padStart(2, "0")
          : currentDate.getHours()) +
        "" +
        +(currentDate.getMinutes() < 10
          ? currentDate.getMinutes().toString().padStart(2, "0")
          : currentDate.getMinutes()) +
        "" +
        (currentDate.getSeconds() < 10
          ? currentDate.getSeconds().toString().padStart(2, "0")
          : currentDate.getSeconds()),
      password = Buffer.from(
        (((shortCode as string) + passKey) as string) + timeStamp
      ).toString("base64");

    return new Promise((resolve, reject) => {
      try {
        if (token instanceof Error == false) {
          let paymentRequest = https.request(
            "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
            {
              method: "POST",
              headers: {
                accept: "application/json",
                "content-type": "application/json",
                authorization: ` Bearer ${
                  (JSON.parse(token) as TokenData).access_token
                }`,
              },
            },
            (response: IncomingMessage) => {
              response.on("error", (error) => {
                reject(error);
              });
              response.on("data", (data: Buffer) => {
                console.log(JSON.parse(data.toString()));
                resolve(data.toString());
              });
            }
          );

          paymentRequest.write(
            JSON.stringify({
              BusinessShortCode: shortCode,
              Password: password,
              Timestamp: timeStamp,
              TransactionType: "CustomerPayBillOnline",
              Amount: amount,
              PartyA: phonenumber,
              PartyB: shortCode,
              PhoneNumber: phonenumber,
              CallBackURL: callbackURL,
              AccountReference: "Test",
              TransactionDesc: "Test",
            })
          );

          paymentRequest.on("error", (error) => reject(error));
          paymentRequest.end();
        } else return "Error occured in creating token";
      } catch (error) {
        reject(error);
      }
    });
  };

export const Payment = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user-token"];

    if (userToken) {
      let user = await retrieveUser(userToken as string),
        paymentInfo: any = "";

      if (typeof user !== "string") {
        request.on("data", (paymentData: Buffer) => {
          paymentInfo += paymentData;
        });
        request.on("end", async () => {
          if (paymentInfo != "") {
            paymentInfo = JSON.parse(paymentInfo);

            if (!paymentInfo.amount || !paymentInfo.phonenumber) {
              response.writeHead(409);
              response.end(
                "Incomplete credentials, pass in a phonenumber and amount, ensure key fields are in small letters"
              );
            } else {
              new Promise(async (resolve, reject) => {
                let PaymentProcess = await makePayment(
                  paymentInfo.phonenumber,
                  paymentInfo.amount
                );

                if (PaymentProcess instanceof Error == false)
                  resolve(PaymentProcess);
                else reject(PaymentProcess);
              })
                .then(() => {
                  global.User = user.id;
                  response.writeHead(201);
                  response.end("Payment initiated");
                })
                .catch((error) => {
                  response.writeHead(500);
                  response.end(
                    "Error in creating the payment request, please try again later" +
                      error.message
                  );
                });
            }
          } else {
            response.writeHead(409);
            response.end(
              "Ensure you pass in payment details i.e. phonenumber and amount"
            );
          }
        });
      } else {
        response.writeHead(403);
        response.end("Token is invalid, please log in or sign up");
      }
    } else {
      response.writeHead(401);
      response.end(
        "Unauthenticated, pass in an authentication token to continue"
      );
    }
  },
  Redirect = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    try {
      let paymentResponse: any = "";

      request.on("data", (data: Buffer) => {
        paymentResponse += data.toString();
      });
      request.on("end", async () => {
        let { Body }: PaymentResponse = JSON.parse(paymentResponse),
          { ResultCode, CallbackMetadata } = Body.stkCallback,
          amount =
            CallbackMetadata.Item[
              CallbackMetadata.Item.findIndex((item) => item.Name == "Amount")
            ].Value;

        if (ResultCode == "0") {
          let processFunds = await updateFunds(global.User as string, amount);

          switch (processFunds) {
            case "Successful update":
              response.writeHead(200);
              response.end("Successful payment");
              break;
            case "User does not exist in the database":
              response.writeHead(404);
              response.end("User is not in the database");
              break;
            case "Non-existent user":
              response.writeHead(401);
              response.end("Expired token passed in, please log in again");
              break;
            case "Incomplete credentials":
              response.writeHead(409);
              response.end("Incomplete credentials passed in");
              break;
            default:
              response.writeHead(500);
              response.end("Server failure, please try again");
              break;
          }
        } else {
          response.writeHead(405);
          response.end("Payment did not go through, try again");
        }

        global.User = null;
      });
    } catch (error) {
      response.writeHead(500);
      response.end("Server error, please try again");
    }
  };
