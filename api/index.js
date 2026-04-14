require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');

// Route imports
const createRewardsRouter = require('./routes/rewards');
const setsRouter = require('./routes/sets');
const cardsRouter = require('./routes/cards');

const app = express();
app.use(express.json());
app.use(cors());

// MongoDB connection info
const uri = process.env.MONGODB_URI;
const dbName = 'COP4331Cards';
let db;
let usersCollection;
let rewardsCollection;

// Connect Mongoose (used by Sets and Cards models)
mongoose.connect(uri)
    .then(() => console.log('Mongoose connected'))
    .catch(err => console.error('Mongoose connection error:', err));

// Connect native MongoClient (used by auth, rewards, quiz)
MongoClient.connect(uri)
    .then(client => {
        db = client.db(dbName);
        usersCollection = db.collection('Users');
        rewardsCollection = db.collection('Rewards');

        // Mount routes
        app.use('/api/rewards', createRewardsRouter(rewardsCollection));
        app.use('/api/sets', setsRouter);       // Study sets CRUD
        app.use('/api', cardsRouter);            // Cards CRUD (routes handle /sets/:setId/cards and /cards/:cardId)

        console.log('Connected to the database');

        const port = process.env.PORT || 5000;
        app.listen(port, () => {
            console.log(`Server is running on port ${port}`);
        });
    })
    .catch(err => {
        console.error('Error connecting to the database', err);
        process.exit(1);
    });


// ─── Auth Routes (inline) ────────────────────────────────────

// Registration API
app.post('/api/register', async (req, res) => {
    try {
        const { firstName, lastName, login, email, password } = req.body;

        const existingUser = await usersCollection.findOne({
            $or: [{ login }, { email }]
        });

        if (existingUser) {
            return res.status(409).json({ error: "User already exists." });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = {
            firstName,
            lastName,
            login,
            email,
            password: hashedPassword,
            createdAt: new Date()
        };

        await usersCollection.insertOne(user);

        res.status(201).json({ message: "Account created successfully. Please log in." });

    } catch (err) {
        res.status(500).json({ error: "Registration failed." });
    }
});

// Login API
app.post('/api/login', async (req, res) => {
    try {
        const { login, password } = req.body;

        const user = await usersCollection.findOne({ login: login });

        if (!user) {
            return res.status(401).json({ error: "User/Password combination incorrect" });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ error: "User/Password combination incorrect" });
        }

        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(200).json({
            id: user._id.toString(),
            firstName: user.firstName,
            lastName: user.lastName,
            login: user.login,
            token: token
        });

    } catch (err) {
        res.status(500).json({ error: "Server error. Please try again." });
    }
});
