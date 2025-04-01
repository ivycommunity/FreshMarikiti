import { retrieveUser } from "../Routes/AccountCRUD";
import { IncomingMessage, ServerResponse } from "http";
import * as https from "https";
import * as dotenv from "dotenv";

dotenv.config({
  path: "./.env",
});

type PaymentDetails = {
  phoneNumber: string;
  amount: number;
};
type TokenData = {
  access_token: string;
  expires_in: string;
};

const consumerKey = process.env.MPESA_CKEY,
  consumerSecret = process.env.MPESA_CSECRET,
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
        "finish",
        () => (returnToken = JSON.parse(JSON.stringify(returnToken)))
      );
      requestToken.on("close", () => {
        returnToken && resolve(returnToken);
      });

      requestToken.end();
    });
  },
  makePayment = async (phoneNumber: string, amount: number) => {
    await Token()
      .then((token) => JSON.parse(token) as TokenData)
      .then((authToken) => {
        let paymentRequest = https.request(
          "https://sandbox.safaricom.co.ke/mpesa/b2b/v1/paymentrequest",
          {
            method: "POST",
            headers: {
              accept: "application/json",
              "content-type": "application/json",
              authorization: `Bearer ${authToken.access_token}`,
            },
          },
          (response: IncomingMessage) => {
            response.on("error", (error) => {
              console.log(error);
            });
            response.on("data", (data: Buffer) => {
              console.log(data.toString());
            });
          }
        );

        paymentRequest.write(
          JSON.stringify({
            Initiator: "Node.js",
            SecurityCredential:
              "j/nFOPquDCKDDzbyufrs3OOgLt2R/tWdZO8g9uJwyH+kFIlS/Et96oPHBHavURvXycASsfyIWx4mHpXoXzaTiSXgVrpzETL8TjnkEyJ9dYToeDgID6reAnIfP5dkirTj280y6hFlXT1MxyDtaegqd5GfLC/o5h2E4IbdqD4uv5vWkP0XzUrI5rzlwJiGYvikHwyoxqS+4yhFOCTorbulaB2YwgMPuqRGfYSa35Jy6qmsn/duxtvUddN7Vvg+CDeMOC087MVk2k5pEanFqhBDSZuvFA/AygoaLAtFWm0kJbW7V2yMcExPd49MNOyO6Nq2eY8pzU0EBXZwF1FQDkJYyQ==",
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
              "https://5170-197-237-31-188.ngrok-free.app/payment/redirect",
            ResultURL:
              "https://5170-197-237-31-188.ngrok-free.app/payment/timeout",
          })
        );
        paymentRequest.end();
      })
      .catch((error) => {
        console.log(error);
      });
  };

export const Payment = async (
  request: IncomingMessage,
  response: ServerResponse<IncomingMessage>
) => {
  let userToken = request.headers["user_token"];

  if (userToken) {
    let user = await retrieveUser(userToken as string);

    if (user) {
      return new Promise((resolve, reject) => {
        let payerData: string = "";

        request.on("data", async (Data: Buffer) => {
          payerData += Data.toString();
        });
        request.on("end", () => {
          resolve(JSON.parse(payerData));
        });
        request.on("error", (error) => {
          reject(error);
        });
      })
        .then((data) => data as PaymentDetails)
        .then((paymentData) => {
          makePayment(paymentData.phoneNumber, paymentData.amount);
          return response.end(paymentData);
        })
        .catch((error) => {
          return response.end(error);
        });
    } else {
      response.writeHead(403);
      response.end("Expired access Token and refresh token does not exist");
      return;
    }
  }
};
