import * as admin from "firebase-admin";
import path from "path";

var serviceAccount = require(path.join(
  path.resolve(
    __dirname,
    "../",
    "fresh-mar-server-firebase-adminsdk-fbsvc-5917950009.json"
  )
));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export const sendNotification = async ({
  title,
  body,
  token,
}: {
  title: string;
  body: string;
  token: string;
}): Promise<any | Error> => {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    return new Promise(async (resolve, reject) => {
      let sender: any = await admin.messaging().send(message);

      if (sender instanceof Error) reject(sender);
      else resolve("Success");
    });
  } catch (error) {
    return error as Error;
  }
};
