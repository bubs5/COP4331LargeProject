const express = require('express');
const router = express.Router();
const Card = require('../models/Card');
const jwt = require('jsonwebtoken');

// Helper: extract userId from JWT token if present
function getUserId(req) {
    try {
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            return decoded.userId || decoded.id || 'unknown';
        }
    } catch (err) {
        // Token invalid or missing — fall through
    }
    return 'unknown';
}

// GET /api/sets/:setId/cards
// Returns all cards for a set, wrapped in { flashcards: [...] }
router.get('/sets/:setId/cards', async (req, res) => {
    try {
        const cards = await Card.find({ setId: req.params.setId });
        res.json({ flashcards: cards });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/sets/:setId/cards
// Creates a new card, returns { flashcard: {...} }
router.post('/sets/:setId/cards', async (req, res) => {
    try {
        const { term, definition } = req.body;
        const userId = getUserId(req);

        const newCard = new Card({
            term,
            definition,
            setId: req.params.setId,
            userId,
        });

        await newCard.save();
        res.status(201).json({ flashcard: newCard });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /api/cards/:cardId
// Updates a card, returns { flashcard: {...} }
router.put('/cards/:cardId', async (req, res) => {
    try {
        const { term, definition } = req.body;

        const updatedCard = await Card.findByIdAndUpdate(
            req.params.cardId,
            { term, definition },
            { new: true }
        );

        if (!updatedCard) {
            return res.status(404).json({ error: 'Card not found.' });
        }

        res.json({ flashcard: updatedCard });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE /api/cards/:cardId
// Deletes a single card
router.delete('/cards/:cardId', async (req, res) => {
    try {
        const deleted = await Card.findByIdAndDelete(req.params.cardId);

        if (!deleted) {
            return res.status(404).json({ error: 'Card not found.' });
        }

        res.json({ message: 'Card deleted.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
