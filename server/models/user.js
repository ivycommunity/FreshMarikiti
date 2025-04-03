const mongoose = require("mongoose")

const userSchema = mongoose.Schema({
    email: {
        required: true,
        type: String,
        trim: true,
        validate: {
            validator: (value) => {
            },
        }
    },
    name: {
        required: true,
        type: String,
        trim: true,
    },
    password: {
        required: true,
        type: String,
    }
})

const User = mongoose.model("User", userSchema)
module.exports = User