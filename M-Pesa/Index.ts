import { IncomingMessage, ServerResponse } from "http";
import * as http from "http";
import axios from "axios";

type MpesaResponse = {
  access_token: string;
  expires_in: string;
};
type PaymentRequest = {
  phoneNumber: string;
  amount: number;
};

const getAccessToken = async (): Promise<Error | any> => {
  const consumerKey = process.env.MPESA_CONSUMER_KEY,
    consumerSecret = process.env.MPESA_CONSUMER_SECRET,
    authToken = Buffer.from(`${consumerKey}:${consumerSecret}`).toString(
      "base64"
    );

  try {
    const requestToken = await axios.get(
      "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      {
        method: "GET",
        headers: {
          Authorization: `Basic ${authToken}`,
        },
      }
    );
    return requestToken.data;
  } catch (error) {
    console.log("Error occured in access token generation");
    return error;
  }
};

const MpesaPayment = async (
  phoneNumber: string,
  amount: number,
  accesstoken: string
): Promise<any | Error> => {
  const timeStamp = new Date()
      .toISOString()
      .replace(/[-:T.]/g, "")
      .slice(0, 14),
    pass = Buffer.from(
      (process.env.MPESA_SHORTCODE as string) +
        (process.env.MPESA_PASSKEY as string)
    ).toString("base64");

  const payload = {
    BusinessShortCode: process.env.MPESA_SHORTCODE,
    Password: pass,
    Timestamp: timeStamp,
    TransactionType: "CustomerPayBillOnline", // To change to till number --> CustomerBuyGoodsOnline
    Amount: amount, //Should always be 1 or greater, never 0 --> 0 returns JSON error in conversion to object
    PartyA: "254" + phoneNumber.substring(1),
    PartyB: process.env.MPESA_SHORTCODE,
    PhoneNumber: "254" + phoneNumber.substring(1),
    CallBackURL: process.env.MPESA_CALLBACK_URL,
    AccountReference: "254" + phoneNumber.substring(1),
    TransactionDesc: "Fresh Marikiti application payment process, Thank you!",
  };

  try {
    const paymentResponse = await axios.post(
      "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      {
        payload,
        headers: {
          Authorization: `Bearer ${accesstoken}`,
        },
      }
    );
    if (paymentResponse.data) return paymentResponse.data;
  } catch (error) {
    return error;
  }
};

const Server = http.createServer(
  async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    if (request.url == "/") {
      let request = await getAccessToken();
      response.end(`${request}`);
    } else if (request.url == "/stkPush" && request.method == "POST") {
      let data: string = "";

      request.on("data", (chunk) => {
        data += chunk.toString();
      });

      request.on("end", async () => {
        if (data.length > 0) {
          let body: PaymentRequest = JSON.parse(data);
          const access_token: MpesaResponse = await getAccessToken();

          await MpesaPayment(
            body.phoneNumber,
            body.amount,
            access_token.access_token
          )
            .then((data) => {
              if (data.status == 404) {
                response.writeHead(404, {
                  "content-type": "application/json",
                });
                response.end(
                  "Invalid header credentials passed, check on your credentials in the auth header and on your payload i.e. consumer key, secret, passkey and callback url"
                );
              } else {
                response.writeHead(200, {
                  "content-type": "text/plain",
                });
                response.end("Successful");
              }
            })
            .catch((error) => {
              response.end(error);
            });
        } else {
          response.writeHead(400, {
            "content-type": "text/plain",
          });
          response.end("No body parsed into the request");
        }
      });
    } else if (request.url == "/callback") {
      if (response.statusCode == 200) response.end("Payment Recieved");
    } else {
      response.end(
        "Fresh Marikiti Server API, your accessing a protected route that can get you sued"
      );
    }
  }
);

Server.listen(process.env.PORT || 3000, () => {
  process.stdout.write("Server is running at port 3000");
});

process.on("uncaughtException", (error) => {
  console.log(error.message);
  console.log(error.stack);
});
