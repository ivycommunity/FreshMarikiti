"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var http = require("http");
var axios_1 = require("axios");
var getAccessToken = function () { return __awaiter(void 0, void 0, void 0, function () {
    var consumerKey, consumerSecret, authToken, requestToken, error_1;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                consumerKey = process.env.MPESA_CONSUMER_KEY, consumerSecret = process.env.MPESA_CONSUMER_SECRET, authToken = Buffer.from("".concat(consumerKey, ":").concat(consumerSecret)).toString("base64");
                _a.label = 1;
            case 1:
                _a.trys.push([1, 3, , 4]);
                return [4 /*yield*/, axios_1.default.get("https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials", {
                        method: "GET",
                        headers: {
                            Authorization: "Basic ".concat(authToken),
                        },
                    })];
            case 2:
                requestToken = _a.sent();
                return [2 /*return*/, requestToken.data];
            case 3:
                error_1 = _a.sent();
                console.log("Error occured in access token generation");
                return [2 /*return*/, error_1];
            case 4: return [2 /*return*/];
        }
    });
}); };
var MpesaPayment = function (phoneNumber, amount, accesstoken) { return __awaiter(void 0, void 0, void 0, function () {
    var timeStamp, pass, payload, paymentResponse, error_2;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                timeStamp = new Date()
                    .toISOString()
                    .replace(/[-:T.]/g, "")
                    .slice(0, 14), pass = Buffer.from(process.env.MPESA_SHORTCODE +
                    process.env.MPESA_PASSKEY).toString("base64");
                payload = {
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
                _a.label = 1;
            case 1:
                _a.trys.push([1, 3, , 4]);
                return [4 /*yield*/, axios_1.default.post("https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest", {
                        payload: payload,
                        headers: {
                            Authorization: "Bearer ".concat(accesstoken),
                        },
                    })];
            case 2:
                paymentResponse = _a.sent();
                if (paymentResponse.data)
                    return [2 /*return*/, paymentResponse.data];
                return [3 /*break*/, 4];
            case 3:
                error_2 = _a.sent();
                return [2 /*return*/, error_2];
            case 4: return [2 /*return*/];
        }
    });
}); };
var Server = http.createServer(function (request, response) { return __awaiter(void 0, void 0, void 0, function () {
    var request_1, data_1;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                if (!(request.url == "/")) return [3 /*break*/, 2];
                return [4 /*yield*/, getAccessToken()];
            case 1:
                request_1 = _a.sent();
                response.end("".concat(request_1));
                return [3 /*break*/, 3];
            case 2:
                if (request.url == "/stkPush" && request.method == "POST") {
                    data_1 = "";
                    request.on("data", function (chunk) {
                        data_1 += chunk.toString();
                    });
                    request.on("end", function () { return __awaiter(void 0, void 0, void 0, function () {
                        var body, access_token;
                        return __generator(this, function (_a) {
                            switch (_a.label) {
                                case 0:
                                    if (!(data_1.length > 0)) return [3 /*break*/, 3];
                                    body = JSON.parse(data_1);
                                    return [4 /*yield*/, getAccessToken()];
                                case 1:
                                    access_token = _a.sent();
                                    return [4 /*yield*/, MpesaPayment(body.phoneNumber, body.amount, access_token.access_token)
                                            .then(function (data) {
                                            if (data.status == 404) {
                                                response.writeHead(404, {
                                                    "content-type": "application/json",
                                                });
                                                response.end("Invalid header credentials passed, check on your credentials in the auth header and on your payload i.e. consumer key, secret, passkey and callback url");
                                            }
                                            else {
                                                response.writeHead(200, {
                                                    "content-type": "text/plain",
                                                });
                                                response.end("Successful");
                                            }
                                        })
                                            .catch(function (error) {
                                            response.end(error);
                                        })];
                                case 2:
                                    _a.sent();
                                    return [3 /*break*/, 4];
                                case 3:
                                    response.writeHead(400, {
                                        "content-type": "text/plain",
                                    });
                                    response.end("No body parsed into the request");
                                    _a.label = 4;
                                case 4: return [2 /*return*/];
                            }
                        });
                    }); });
                }
                else if (request.url == "/callback") {
                    if (response.statusCode == 200)
                        response.end("Payment Recieved");
                }
                else {
                    response.end("Fresh Marikiti Server API, your accessing a protected route that can get you sued");
                }
                _a.label = 3;
            case 3: return [2 /*return*/];
        }
    });
}); });
Server.listen(process.env.PORT || 3000, function () {
    process.stdout.write("Server is running at port 3000");
});
process.on("uncaughtException", function (error) {
    console.log(error.message);
    console.log(error.stack);
});
