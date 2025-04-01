const express = require("express");
const mongoose = require("mongoose");

const PORT = process.env.PORT || 3000;
const app = express(); // initialize express package as variable

app.use(express.json()); // middleware -request passed come in json format

app.listen(PORT, "0.0.0.0", () => {
    console.log('connected at port ${PORT}');
});