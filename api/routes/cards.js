const express = require('express');
const router = express.Router();
const Card = require('../models/Card');


//Get sets
router.get('/sets/:setId/cards', async (req, res) => {
    try {
        const cards = await Card.find({ setId: req.params.setId });
        res.json(cards);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

//Post sets
router.post('/sets/:setId/cards', async (req, res) => {
    try {
        const { term, definition } = req.body;

        // Replace later with real auth
        const userId = "mockUser123";
        const newCard = new Card({
            term,
            definition,
            setId: req.params.setId,
            userId
        });

        await newCard.save();
        res.status(201).json(newCard);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

//Put cards
router.put('/cards/:cardId', async (req, res) => {
    try {
        const { term, definition } = req.body;

        const updatedCard = await Card.findByIdAndUpdate(
            req.params.cardId,
            { term, definition },
            { new: true }
        );
        res.json(updatedCard);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

//Delete cards
router.delete('/cards/:cardId', async (req, res) => {
    try {
        await Card.findByIdAndDelete(req.params.cardId);
        res.json({ message: "Card deleted" });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
