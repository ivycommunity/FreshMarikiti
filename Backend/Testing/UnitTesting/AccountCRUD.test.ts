import { describe, expect, it, vi } from "vitest";
import { Login, Signup } from "../../Routes/AccountCRUD";
import { IncomingMessage, ServerResponse } from "http";
import { Writable } from "stream";

const requestMsgMock = (options = {}): IncomingMessage => {
    return {
      method: "GET",
      headers: {},
      ...options,
    } as IncomingMessage;
  },
  responseMsgMock = (): ServerResponse => {
    const response = new Writable() as ServerResponse;

    response.writeHead = vi.fn().mockReturnValue(response);
    response.end = vi.fn().mockReturnValue(response);
    return response;
  };

describe("Signup Tests", () => {
  const request = requestMsgMock({
      body: JSON.stringify({
        name: "Lawrence Muchiri",
        email: "llwmuchiri@gmail.com",
        password: "Davidwan1*",
      }),
    }),
    response = responseMsgMock();

  it("Signup process", () => {
    Signup(request, response);
  });
});
