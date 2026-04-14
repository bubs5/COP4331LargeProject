const express = require('express');
const router = express.Router();
const Set = require('../models/Set');
const Card = require('../models/Card');

// GET /api/sets?userId=...
// Returns all study sets for a user, with cardCount computed per set
router.get('/', async (req, res) => {
    try {
        const { userId } = req.query;

        const filter = userId ? { userId } : {};
        const sets = await Set.find(filter).sort({ createdAt: -1 });

        // Count cards for each set
        const studySets = await Promise.all(
            sets.map(async (set) => {
                const cardCount = await Card.countDocuments({ setId: set._id.toString() });
                return {
                    _id: set._id,
                    title: set.title,
                    description: set.description,
                    userId: set.userId,
                    cardCount,
                    createdAt: set.createdAt,
                    updatedAt: set.updatedAt,
                };
            })
        );

        res.json({ studySets });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/sets/:setId
// Returns a single study set with cardCount
router.get('/:setId', async (req, res) => {
    try {
        const set = await Set.findById(req.params.setId);

        if (!set) {
            return res.status(404).json({ error: 'Study set not found.' });
        }

        const cardCount = await Card.countDocuments({ setId: set._id.toString() });

        res.json({
            studySet: {
                _id: set._id,
                title: set.title,
                description: set.description,
                userId: set.userId,
                cardCount,
                createdAt: set.createdAt,
                updatedAt: set.updatedAt,
            },
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/sets
// Creates a new study set
router.post('/', async (req, res) => {
    try {
        const { title, description, userId } = req.body;

        if (!title || !description) {
            return res.status(400).json({ error: 'Title and description are required.' });
        }

        const newSet = new Set({
            title: title.trim(),
            description: description.trim(),
            userId: userId || 'unknown',
        });

        await newSet.save();

        res.status(201).json({
            studySet: {
                _id: newSet._id,
                title: newSet.title,
                description: newSet.description,
                userId: newSet.userId,
                cardCount: 0,
                createdAt: newSet.createdAt,
                updatedAt: newSet.updatedAt,
            },
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE /api/sets/:setId
// Deletes the set AND all cards belonging to it
router.delete('/:setId', async (req, res) => {
    try {
        const set = await Set.findById(req.params.setId);

        if (!set) {
            return res.status(404).json({ error: 'Study set not found.' });
        }

        // Delete all cards in this set
        await Card.deleteMany({ setId: req.params.setId });

        // Delete the set itself
        await Set.findByIdAndDelete(req.params.setId);

        res.json({ message: 'Set deleted.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
