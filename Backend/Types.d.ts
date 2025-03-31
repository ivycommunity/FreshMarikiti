import { IncomingMessage } from "http";

declare module "http" {
  interface IncomingMessage {
    User?: any | null;
  }
}

export {};
