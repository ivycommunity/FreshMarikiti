//CRUD -> signup/login, Update user data,Delete user data
import * as https from "https";
import { IncomingMessage, ServerResponse } from "http";
import Schema from "./../Database/Schema";
import * as Url from "url";
import * as queryString from "querystring";
import * as jwt from "jsonwebtoken";

type Validator = (type: "Login" | "Signup", Data: {}) => Promise<string>;
type SignUpCredentials = {
  name: string;
  email: string;
  password: string;
};
type LoginCredentials = {
  email: string;
  password: string;
};
type googleSuccess = {
  access_token: string;
  expires_in: string;
  refresh_token: string;
  scope: string;
  token_type: string;
  id_token: string;
};
type UpdateUserBody = {
  access_token: string;
  name?: string;
  email?: string;
  password?: string;
};

const jwtAccessT = process.env.JWT_ACCESS_TOKEN,
  jwtRefreshT = process.env.JWT_REFRESH_TOKEN,
  googleID = process.env.GOAUTH_ID,
  googleSecret = process.env.GOAUTH_SECRET,
  googleAuthURL = "https://accounts.google.com/o/oauth2/auth",
  scope = "profile email";

const DataStore: Validator = async (type, Data) => {
    try {
      if (type == "Login") {
        let userData: LoginCredentials = Data as LoginCredentials;

        if (userData.email == undefined || userData.password == undefined)
          return "Incomplete credentials";

        const emailValidator: Boolean =
          /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/.test(
            userData.email
          );

        if (emailValidator == false) return "Invalid email";

        let user = await Schema.findOne({ email: userData.email });

        if (!user) return "Non-existent user";
        if (userData.password != user.password) return "Incorrect pass";
        return "Login successful";
      } else {
        let userData: SignUpCredentials = Data as SignUpCredentials;

        if (!userData.name || !userData.email || !userData.password)
          return "Incomplete credentials";

        const emailValidator: Boolean =
            /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/.test(
              userData.email
            ),
          passwordLength: Boolean = userData.password.length > 3;

        if (emailValidator && passwordLength) {
          let success: boolean = false;
          await Schema.insertOne({
            id: "122345",
            name: userData.name,
            email: userData.email,
            password: userData.password,
          })
            .then(() => (success = true))
            .catch(() => (success = false));
          return success
            ? "Successful signup"
            : "Database Failure,signup failed, try again";
        } else return !emailValidator ? "Invalid email" : "Password short";
      }
    } catch (error: any) {
      return error.message;
    }
  },
  generateUserToken = (payload: any) => {
    return jwt.sign(payload, jwtAccessT as string, { expiresIn: 36000 });
  };

export const Signup = (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userData: any = "";

    request.on("data", (data: Buffer) => {
      if (data) userData += data.toString();
    });
    request.on("close", async () => {
      if (userData.length > 0) {
        const signup = await DataStore("Signup", JSON.parse(userData));

        if (signup == "Successful signup") {
          request.User = userData;
          response.writeHead(201, "Successful signup", {
            "content-type": "text/plain",
          });
          response.end("Successful");
        } else {
          switch (signup) {
            case "Incomplete credentials":
              response.writeHead(401, "Incomplete Credentials");
              response.end(
                "Incomplete credentials, provide name,email and password"
              );
              break;
            case "Invalid email":
              response.writeHead(401, "Email Format");
              response.end(
                "Invalid email passed in, ensure email has the correct format"
              );
              break;
            case "Password short":
              response.writeHead(401, "Password Length");
              response.end("Password length is short");
              break;
            default:
              response.writeHead(500, "Server failure");
              response.end("Server failure, please try again");
              break;
          }
        }
      } else {
        response.writeHead(401, "Invalid body Content", {
          "content-type": "text/plain",
        });
        response.end("Pass in a body");
      }
    });
  },
  Login = (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userData: any = "";

    request.on("data", (data: Buffer) => {
      if (data) userData += JSON.parse(data.toString());
    });
    request.on("close", async () => {
      if (userData) {
        const login = await DataStore("Login", userData);

        if (login == "Login successful") {
          request.User = userData;
          response.writeHead(200, "Successful Login");
          response.end("Login successful");
        } else {
          switch (login) {
            case "Non-existant user":
              response.writeHead(404, "User does not exist");
              response.end("User doesn't exist");
              break;
            case "Incorrect pass":
              response.writeHead(401, "Incorrect pass");
              response.end("Incorrect password passed");
              break;
            case "Invalid email":
              response.writeHead(400, "Email format");
              response.end("Invalid email format");
              break;
            default:
              response.writeHead(500, "Server error");
              response.end("Server error occured, please try again");
              break;
          }
        }
      } else {
        response.writeHead(401, "No body Content", {
          "content-type": "text/plain",
        });
        response.end("Pass in a body");
      }
    });
  },
  googleAuthentication = async (response: ServerResponse<IncomingMessage>) => {
    const authUrl = `${googleAuthURL}?client_id=${googleID}&redirect_uri=${encodeURIComponent(
      "http://localhost:3000/accounts/googleredirect"
    )}&response_type=code&scope=${encodeURIComponent(
      scope
    )}&access_type=offline`;

    response.writeHead(302, { Location: authUrl });
    response.end();
  },
  googleUserToken = (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    const parsedURL = Url.parse(request.url as string, true),
      { code } = parsedURL.query;

    if (!code) {
      response.writeHead(403, "Code Invalid");
      response.end("Authentication failed");
      return;
    }
    const postData = queryString.stringify({
      code,
      client_id: googleID,
      client_secret: googleSecret,
      redirect_uri: "http://localhost:3000/accounts/googleredirect",
      grant_type: "authorization_code",
    });

    let tokenRequest = https.request(
      "https://oauth2.googleapis.com/token",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Content-Length": Buffer.byteLength(postData),
        },
      },
      (tokenResponse: IncomingMessage) => {
        let tokenData: any = "";

        tokenResponse.on("data", (Data: Buffer) => {
          tokenData += Data.toString();
        });
        tokenResponse.on("end", async () => {
          if (tokenData) {
            tokenData = JSON.parse(tokenData) as googleSuccess;

            let userRetrieval = https.request(
              "https://www.googleapis.com/oauth2/v2/userinfo",
              {
                method: "GET",
                headers: {
                  authorization: `Bearer ${
                    (tokenData as googleSuccess).access_token
                  }`,
                },
              },
              (userResponse) => {
                let actualUser: any = "";

                userResponse.on("data", (data: Buffer) => {
                  actualUser += data.toString();
                });
                userResponse.on("end", () => {
                  new Promise((resolve, reject) => {
                    if (actualUser)
                      resolve(JSON.parse(actualUser) as googleSuccess);
                    else
                      reject(
                        new Error(
                          "Google authentication failed, token passed in is wrong, please try again"
                        )
                      );
                  })
                    .then((user: any) => {
                      request.User = user;
                      let userToken = generateUserToken(user);

                      if (request.User) {
                        // Schema.insertOne({
                        //   id: request.User.id,
                        //   name: request.User.name,
                        //   email: request.User.email,
                        // });
                        response.end(
                          JSON.stringify({
                            accessToken: userToken,
                            expiresIn: 36000,
                          })
                        );
                        return;
                      } else
                        response.end(
                          "Google authentication failed, please try again"
                        );
                      return;
                    })
                    .catch(() => {
                      response.end("Error in authentication, please try again");
                      return;
                    });
                });
                userResponse.on("error", (error) => {
                  console.log("Called here");
                  console.log(error);
                });
              }
            );

            userRetrieval.on("error", (error) => {
              response.end(
                "Google Authentication error, please try again:" + `${error}`
              );
            });
            userRetrieval.end();
          } else {
            response.end("No token retrieved");
          }
        });
        tokenRequest.on("error", (error) => {
          response.writeHead(500, { "Content-Type": "text/plain" });
          response.end(`Request error: ${error.message}`);
        });
      }
    );

    tokenRequest.write(postData);
    tokenRequest.end();
  },
  retrieveUser = (token: string) => jwt.verify(token, jwtAccessT as string),
  Update = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let details: any | null = null;

    request.on("data", (data: Buffer) => {
      details += data.toString();
    });

    request.on("end", async () => {
      if (details) {
        details = JSON.parse(details);

        let userFinder = retrieveUser((details as UpdateUserBody).access_token),
          userDetails: UpdateUserBody = details;

        if (userFinder) {
          let dbUserFinder = await Schema.findOne({ email: userDetails.email });

          if (dbUserFinder) {
            let newDetails = {
                name: userDetails.name,
                email: userDetails.email,
                password: userDetails.password,
              },
              newValues = Object.entries(newDetails),
              updatedValues: string[] = [];

            for (let [key, value] of newValues) {
              if (value) {
                if (key == "email") {
                  const emailValidator: Boolean =
                    /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/.test(
                      value
                    );
                  if (emailValidator)
                    Schema.updateOne(
                      { email: userDetails.email },
                      { email: value }
                    )
                      .then(() => updatedValues.push("email"))
                      .catch(() => updatedValues.push("emailfail"));
                  else {
                    response.end("Invalid email passed in, please try again");
                    return;
                  }
                } else if (key == "password") {
                  if (value.length < 3) {
                    response.end(
                      "Password length is short, pass in a password length ranging from [3-16]"
                    );
                    return;
                  } else
                    Schema.updateOne(
                      { email: userDetails.email },
                      { password: value }
                    )
                      .then(() => updatedValues.push("password"))
                      .catch(() => updatedValues.push("passwordfail"));
                } else if (key == "name") {
                  if (value.length > 0)
                    Schema.updateOne(
                      { email: userDetails.email },
                      { name: userDetails.name }
                    )
                      .then(() => updatedValues.push("name"))
                      .catch(() => updatedValues.push("namefail"));
                } else {
                  continue;
                }
              }
            }

            response.end(
              `${updatedValues.includes("name") && "Name updated"}, ${
                updatedValues.includes("email") && "Email updated"
              }, ${updatedValues.includes("password") && "Password updated"}, ${
                updatedValues.includes("emailfail") &&
                "Email failed try again please"
              }, ${
                updatedValues.includes("namefail") &&
                "Name failed, try again please"
              }, ${
                updatedValues.includes("passwordfail") &&
                "Password failed,try again please"
              }`
            );
          } else {
            response.writeHead(404, "Non-existent user");
            response.end("User doesn't exist");
          }
        } else {
          response.writeHead(403, "Unauthorized");
          response.end(
            "Expired or invalid token, please sign up or log in again"
          );
        }
      } else {
        response.writeHead(401, "Empty body content");
        response.end(
          "No body passed in, try again with a body within the request"
        );
      }
    });
  },
  EraseUserSession = async (token: string) => {}, // If user exits session/ signs out
  Delete = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let token: any | null = null;

    request.on("data", (data: Buffer) => {
      token += data.toString();
    });
    request.on("end", async () => {
      if (token) {
        let user: any = retrieveUser(token);

        if (user) {
          let userFinder = await Schema.findOne({ email: user.email });
          if (userFinder) {
            Schema.deleteOne({ email: user.email })
              .then(() => response.end("Deletion successful"))
              .catch(() => {
                response.end("Deletion failed, please try again");
              });
          } else {
            response.writeHead(403, "Unauthorised token");
            response.end("Token expired, try again");
          }
        } else {
          response.writeHead(404, "Non-existent user");
          response.end("User does not exist");
        }
      } else {
        response.writeHead(403, "No token passed in");
        response.end(
          "No user token present, please try again, send in an accessToken body"
        );
      }
    });
  };
