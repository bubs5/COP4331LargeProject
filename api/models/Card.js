const mongoose = require('mongoose');

const cardSchema = new mongoose.Schema({
    term: { type: String, required: true },
    definition: { type: String, required: true },
    setId: { type: String, required: true },
    userId: { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model('Card', cardSchema);
