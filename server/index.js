const express = require("express");
const mongoose = require("mongoose");
const authRouter = require("./routes/auth");

const PORT = process.env.PORT || 3000;
const app = express(); // initialize express package as variable

app.use(express.json()); // middleware -request passed come in json format
app.use(authRouter); 

const DB = "mongodb+srv://dbMarikiti:freshmarikiti@cluster0.pjeyrrf.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"

mongoose
    .connect(DB)
    .then(() => {
        console.log("Connection Successful");
    });

app.listen(PORT, "0.0.0.0", () => {
    console.log('connected at port ${PORT}');
});