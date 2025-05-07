//CRUD -> signup/login, Update user data,Delete user data
import * as https from "https";
import { IncomingMessage, ServerResponse } from "http";
import UserSchema from "../Database/Users";
import * as Url from "url";
import * as queryString from "querystring";
import * as jwt from "jsonwebtoken";
import * as crypto from "crypto";
import * as bcrypt from "bcryptjs";
import * as dotenv from "dotenv";

dotenv.config({
  path: "./.env",
});

type Validator = (type: "Login" | "Signup", Data: {}) => Promise<string>;
type SignUpCredentials = {
  name: string;
  email: string;
  password: string;
  goals?: string;
  cart: any[];
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
  id: string;
  name?: string;
  email?: string;
  password?: string;
  goals?: string;
  cart?: any[];
};

const jwtAccessT = process.env.JWT_ACCESS_TOKEN,
  googleID = process.env.GOAUTH_ID,
  googleSecret = process.env.GOAUTH_SECRET,
  googleAuthURL = "https://accounts.google.com/o/oauth2/auth",
  googleTokenURL = "https://oauth2.googleapis.com/token",
  googleRedirectURL = process.env.GOOGLE_REDIRECT,
  scope = "profile email";

const DataStore: Validator = async (type, Data) => {
    try {
      if (type == "Login") {
        let userData: LoginCredentials = Data as LoginCredentials;

        if (userData.email == undefined) return "Incomplete credentials";

        const emailValidator: Boolean =
          /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/gim.test(userData.email);

        if (emailValidator == false) return "Invalid email";

        let user = await UserSchema.findOne({ email: userData.email });

        if (!user) return "Non-existent user";

        if (user.google) return "Login successful";
        if (userData.password) {
          if (
            bcrypt.compareSync(userData.password, user.password as string) ==
            false
          )
            return "Incorrect pass";
          else return "Login successful";
        } else return "Incomplete credentials";
      } else {
        let userData: SignUpCredentials = Data as SignUpCredentials;

        if (!userData.name || !userData.email || !userData.password)
          return "Incomplete credentials";

        const emailValidator: Boolean =
            /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/gim.test(userData.email),
          passwordLength: Boolean = userData.password.length > 3,
          hashedPassword = bcrypt.hashSync(userData.password, 10),
          duplicateFinder = await UserSchema.findOne({ email: userData.email });

        if (emailValidator && passwordLength && !duplicateFinder) {
          let success: boolean = false;

          let storage = await UserSchema.insertOne({
            id: crypto.randomBytes(10).toString("hex"),
            name: userData.name,
            email: userData.email,
            password: hashedPassword,
            goals: userData.goals
              ? userData.goals.length > 0
                ? userData.goals
                : ""
              : "",
            google: false,
            cart: [],
            biocoins: 0,
          });

          if (storage) success = true;

          return success
            ? "Successful signup"
            : "Database Failure,signup failed, try again";
        } else
          return !emailValidator
            ? "Invalid email"
            : !passwordLength
            ? "Password short"
            : "Duplicate user";
      }
    } catch (error: any) {
      return error.message;
    }
  },
  generateUserToken = async (payload: any) => {
    const accessToken = jwt.sign(payload, jwtAccessT as string, {
      expiresIn: "36500s",
    });

    return {
      accessToken: accessToken,
    };
  };

export const Signup = (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    try {
      let userData: any = "";

      request.on("data", (data: Buffer) => {
        if (data) userData += data.toString();
      });
      request.on("close", async () => {
        if (userData.length > 0) {
          const signup = await DataStore("Signup", JSON.parse(userData));

          if (signup == "Successful signup") {
            userData = JSON.parse(userData);
            let userDetails = await UserSchema.findOne({
              email: userData.email,
            });

            let user = await generateUserToken({
              id: userDetails?.id,
              name: userData.name,
              email: userData.email,
              biocoins: userDetails?.biocoins,
              goals: userDetails?.goals,
            });

            if (user instanceof Error == false) {
              response.writeHead(201, "Successful signup", {
                "content-type": "text/plain",
              });
              response.end(
                JSON.stringify({
                  accessToken: user.accessToken,
                })
              );
            }
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
              case "Duplicate user":
                response.writeHead(409);
                response.end("Duplicate user, email already exists");
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
    } catch (error) {
      console.log(error);
    }
  },
  Login = (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    try {
      let userData: any = "";

      request.on("data", (data: Buffer) => {
        if (data) userData += data.toString();
      });
      request.on("end", async () => {
        if (userData) {
          const login = await DataStore("Login", JSON.parse(userData));

          if (login == "Login successful") {
            let user = JSON.parse(userData),
              userDetails = await UserSchema.findOne({ email: user.email });

            if (userDetails) {
              let encodedUser = await generateUserToken({
                id: userDetails.id,
                name: userDetails.name,
                email: userDetails.email,
                biocoins: userDetails.biocoins,
                goals: userDetails.goals,
              });

              if (encodedUser instanceof Error == false) {
                response.writeHead(200, "Successful Login");
                response.end(
                  JSON.stringify({
                    accessToken: encodedUser.accessToken,
                  })
                );
                return;
              } else {
                response.writeHead(500);
                response.end("Server error, please try again");
                return;
              }
            }
          } else {
            switch (login) {
              case "Non-existent user":
                response.writeHead(404, "User does not exist");
                response.end("User doesn't exist");
                break;
              case "Incorrect pass":
                response.writeHead(401, "Incorrect pass");
                response.end("Incorrect password passed");
                break;
              case "Incomplete credentials":
                response.writeHead(401, "Incomplete Credentials");
                response.end("Provide all credentials i.e. email and password");
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
    } catch (error) {
      console.log(error);
    }
  },
  googleAuthentication = async (response: ServerResponse<IncomingMessage>) => {
    const authUrl = `${googleAuthURL}?client_id=${googleID}&redirect_uri=${encodeURIComponent(
      googleRedirectURL as string
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
      { code, error } = parsedURL.query;

    if (!code || error) {
      response.writeHead(403, "Code Invalid");
      response.end("Authentication failed, user rejected");
      return;
    }

    const postData = queryString.stringify({
      code,
      client_id: googleID,
      client_secret: googleSecret,
      redirect_uri: googleRedirectURL,
      grant_type: "authorization_code",
    });

    let tokenRequest = https.request(
      googleTokenURL,
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
                    .then(async (user: any) => {
                      let newUserId = crypto.randomBytes(16).toString("hex"),
                        userToken = generateUserToken({
                          id: newUserId,
                          name: user.name,
                          email: user.email,
                          cart: [],
                        }),
                        duplicateFinder = await UserSchema.findOne({
                          email: user.email,
                        });

                      if (!duplicateFinder) {
                        await UserSchema.insertOne({
                          id: newUserId,
                          name: user.name,
                          email: user.email,
                          biocoins: 0,
                          google: true,
                          cart: [],
                        });
                        response.writeHead(201);
                        response.end(
                          JSON.stringify({
                            accessToken: (await userToken).accessToken,
                            expiresIn: 36000,
                          })
                        );
                        return;
                      } else {
                        response.writeHead(409);
                        response.end("Email already exists");
                        return;
                      }
                    })
                    .catch(() => {
                      response.writeHead(500);
                      response.end("Error in authentication, please try again");
                      return;
                    });
                });
                userResponse.on("error", () => {
                  response.writeHead(500);
                  response.end("Error occured please try again");
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
  retrieveUser = async (accesstoken: string) => {
    try {
      let tokenVerification = jwt.verify(accesstoken, jwtAccessT as string);
      return tokenVerification;
    } catch (error: any) {
      if (error instanceof jwt.TokenExpiredError) return "Expired";
      else return "Invalid token";
    }
  },
  Update = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let details: any = "",
      userAccessToken = request.headers["user_token"];

    if (userAccessToken) {
      request.on("data", (data: Buffer) => {
        details += data.toString();
      });

      request.on("end", async () => {
        if (details != null) {
          let userFinder = await retrieveUser(userAccessToken as string),
            userDetails: UpdateUserBody = JSON.parse(details);

          if (userFinder) {
            let dbUserFinder = await UserSchema.findOne({
              id: userDetails.id,
            });

            if (dbUserFinder) {
              let newDetails = {
                  name: userDetails.name,
                  email: userDetails.email,
                  password: userDetails.password,
                  cart: userDetails.cart,
                },
                newValues = Object.entries(newDetails),
                updatedValues: string[] = [];

              for (let [key, value] of newValues) {
                if (value) {
                  if (key == "email") {
                    const emailValidator: Boolean =
                      /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/.test(
                        value as string
                      );
                    if (emailValidator) {
                      let update = await UserSchema.updateOne(
                        { id: userDetails.id },
                        { email: value }
                      );

                      if (update) updatedValues.push("email");
                      else updatedValues.push("emailfail");
                    } else {
                      response.end("Invalid email passed in, please try again");
                      return;
                    }
                  } else if (key == "password") {
                    if (value.length < 3) {
                      response.end(
                        "Password length is short, pass in a password length ranging from [3-16]"
                      );
                      return;
                    } else {
                      let update = await UserSchema.updateOne(
                        { id: userDetails.id },
                        { password: bcrypt.hashSync(value as string, 10) }
                      );

                      if (update) updatedValues.push("password");
                      else updatedValues.push("passwordfail");
                    }
                  } else if (key == "name") {
                    if (value.length > 0) {
                      let update = await UserSchema.updateOne(
                        { id: userDetails.id },
                        { name: userDetails.name }
                      );

                      if (update) updatedValues.push("name");
                      else updatedValues.push("namefail");
                    }
                  } else if (key == "goals") {
                    if (typeof value == "string" && value.length > 0) {
                      let update = await UserSchema.updateOne(
                        { id: userDetails.id },
                        { goals: value }
                      );

                      if (update) updatedValues.push("goals");
                      else updatedValues.push("goalsfail");
                    }
                  } else {
                    continue;
                  }
                }
              }
              response.writeHead(201);
              response.end(
                `${updatedValues.includes("name") && "Name updated"}, ${
                  updatedValues.includes("email") && "Email updated"
                }, ${updatedValues.includes("password") && "Password updated"},
                ${updatedValues.includes("cart") && "Cart updated"},
                ${updatedValues.includes("goals") && "Goals updated"}, 
                 ${
                   updatedValues.includes("emailfail") &&
                   "Email failed try again please"
                 }, ${
                  updatedValues.includes("namefail") &&
                  "Name failed, try again please"
                }, ${
                  updatedValues.includes("passwordfail") &&
                  "Password failed,try again please"
                }, ${
                  updatedValues.includes("cartfail") &&
                  "Cart addition failed please try again"
                }, ${
                  updatedValues.includes("goals") &&
                  "Goals change has not been made, please try again"
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
    } else {
      response.writeHead(401, "Unauthorized");
      response.end(
        "Authenticate yourself first, pass in an access token and refresh token"
      );
    }
  },
  Delete = async (
    request: IncomingMessage,
    response: ServerResponse<IncomingMessage>
  ) => {
    let userToken = request.headers["user_token"];

    if (userToken) {
      let user: any = retrieveUser(userToken as string);

      if (user) {
        let userFinder = await UserSchema.findOne({ id: user.id });

        if (userFinder) {
          let Deletion = await UserSchema.deleteOne({ id: user.id });

          if (Deletion) {
            response.writeHead(204);
            response.end("Deletion successful");
          } else {
            response.writeHead(500);
            response.end("Deletion failed: Server error, try again please");
          }
        } else {
          response.writeHead(403, "Unauthorised token");
          response.end("Token expired, try again");
        }
      } else {
        response.writeHead(404, "Non-existent user");
        response.end("User does not exist");
      }
    } else {
      response.writeHead(401);
      response.end("Unauthenticated, authenticate yourself");
    }
  };
