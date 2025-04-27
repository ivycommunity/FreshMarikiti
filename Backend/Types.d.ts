import "socket.io";

declare global {
  var User: string | null;
}

declare module "socket.io" {
  interface Socket {
    username?: string;
  }
}
// Hello there
export {};
