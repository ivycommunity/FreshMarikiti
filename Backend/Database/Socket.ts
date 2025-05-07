import mongoose from "mongoose";

interface socketUser {
  userId: string;
  socketId: string;
  connectedAt: Date;
}

const SocketsDb = new mongoose.Schema<socketUser>({
  userId: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  socketId: {
    type: mongoose.SchemaTypes.String,
    required: true,
  },
  connectedAt: {
    type: mongoose.SchemaTypes.Date,
    required: true,
  },
});

const SocketDb = mongoose.model("Sockets", SocketsDb);

export default SocketDb;
