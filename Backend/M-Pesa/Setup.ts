import { retrieveUser } from "../Routes/AccountCRUD";
import { IncomingMessage, ServerResponse } from "http";
import * as dotenv from "dotenv";
import * as https from "https";

dotenv.config({
  path: "./.env",
});

type PaymentDetails = {
  phonenumber: string;
  amount: number;
};
type TokenData = {
  access_token: string;
  expires_in: string;
};

const consumerKey = process.env.MPESA_CKEY,
  consumerSecret = process.env.MPESA_CSECRET,
  passKey = process.env.MPESA_PASSKEY,
  shortCode = process.env.MPESA_SHORTCODE;

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
    const token = await Token();
    return new Promise((resolve, reject) => {
      try {
        if (token instanceof Error == false) {
          let paymentRequest = https.request(
            "https://sandbox.safaricom.co.ke/mpesa/b2b/v1/paymentrequest",
            {
              method: "POST",
              headers: {
                accept: "application/json",
                "content-type": "application/json",
                authorization: ` Bearer ${
                  (JSON.parse(token) as TokenData).access_token
                }`,
                "ngrok-skip-browser-warning":
                  "always please, your annoying as ff broo",
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
              Initiator: "testapi",
              SecurityCredential: passKey,
              CommandID: "BusinessBuyGoods",
              SenderIdentifierType: "4",
              RecieverIdentifierType: 4,
              Amount: amount,
              PartyA: shortCode, //short code
              PartyB: "000000",
              AccountReference: "353353",
              Requester: phoneNumber,
              Remarks: "Payment successful",
              QueueTimeOutURL:
                "https://f226-102-140-206-210.ngrok-free.app/payments/timeout",
              ResultURL:
                "https://f226-102-140-206-210.ngrok-free.app/payments/redirect",
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
                .then((info: any) => JSON.parse(info))
                .then((paymentInfo) => {
                  if (paymentInfo.ResponseCode == "0") {
                    response.writeHead(201);
                    response.end("Payment process initiated");
                  } else {
                    response.writeHead(500);
                    response.end(
                      "Payment process aborted, server error. Try again later"
                    );
                  }
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
  Success = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    try {
      console.log("Success got called");
      let paymentResponse: any = "";

      response.writeHead(200);
      response.end("Successful payment");

      request.on("data", (data: Buffer) => {
        paymentResponse += data.toString();
      });
      request.on("end", () => {
        console.log(JSON.parse(paymentResponse));
      });
    } catch (error) {
      console.log(error);
    }
  },
  Timeout = (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    try {
      console.log("Timeout got called");
      let Error: any = "";

      response.writeHead(200);
      response.end("Payment timed out");

      request.on("data", (Data: Buffer) => {
        Error += Data.toString();
      });
      request.on("end", () => {
        console.log(JSON.parse(Error));
      });
    } catch (error) {
      response.end("Payment process Timed out");
    }
  };
