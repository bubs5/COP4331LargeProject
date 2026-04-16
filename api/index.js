require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');


// Route imports
const createRewardsRouter = require('./routes/rewards');
const setsRouter = require('./routes/sets');
const cardsRouter = require('./routes/cards');
const { sendVerificationEmail, sendPasswordResetEmail } = require('./routes/email');

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
            return res.status(200).json({ error: "User already exists." });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const verificationToken = crypto.randomBytes(32).toString('hex');

        const user = {
            firstName,
            lastName,
            login,
            email,
            password: hashedPassword,
            isVerified: false,
            verificationToken,
            verificationTokenExpires: new Date(Date.now() + 24 * 60 * 60 * 1000),
            createdAt: new Date()
        };

        await usersCollection.insertOne(user);

        await sendVerificationEmail(email, verificationToken);

        res.status(201).json({ message: "Account created successfully. Please check your email to verify your account." });

    } catch (err) {
        console.error('Registration failed:', err);
        res.status(500).json({ error: "Registration failed." });
    }
});

const verifyEmail = async (req, res) => {
    try {
        const { token } = req.query;

        if (!token) {
            return res.status(400).json({ error: 'Verification token is missing.' });
        }

        const user = await usersCollection.findOne({ verificationToken: token });

        if (!user) {
            return res.status(400).json({ error: 'Invalid or expired verification token.' });
        }

        if (user.verificationTokenExpires < new Date()) {
            return res.status(400).json({ error: 'Token has expired. Please request a new verification email.' });
        }

        await usersCollection.updateOne(
            { _id: user._id },
            {
                $set: {
                    isVerified: true
                },
                $unset: {
                    verificationToken: '',
                    verificationTokenExpires: ''
                }
            }
        );

        return res.status(200).json({ message: 'Email verified successfully.' });
    } catch (err) {
        return res.status(500).json({ error: 'Email verification failed.' });
    }
};

// Email verification API
app.get('/api/verify-email', verifyEmail);
app.get('/verify-email', verifyEmail);

// Login API
app.post('/api/login', async (req, res) => {
    try {
        const { login, password } = req.body;

        const user = await usersCollection.findOne({ login: login });

        if (!user) {
            return res.status(200).json({ error: "User/Password combination incorrect" });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(200).json({ error: "User/Password combination incorrect" });
        }

        if (user.isVerified === false) {
            return res.status(200).json({ error: 'Please verify your email address before logging in.' });
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

// Forgot password API
app.post('/api/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ error: 'Email is required.' });
        }

        const user = await usersCollection.findOne({ email });

        // Do not reveal whether the email exists.
        if (!user) {
            return res.status(200).json({ message: 'If that email exists, a reset link has been sent.' });
        }

        const resetToken = crypto.randomBytes(32).toString('hex');
        const resetTokenExpires = new Date(Date.now() + 60 * 60 * 1000);

        await usersCollection.updateOne(
            { _id: user._id },
            {
                $set: {
                    resetToken,
                    resetTokenExpires
                }
            }
        );

        await sendPasswordResetEmail(email, resetToken);

        return res.status(200).json({ message: 'If that email exists, a reset link has been sent.' });
    } catch (err) {
        return res.status(500).json({ error: 'Could not process forgot password request.' });
    }
});

// Reset password API
app.post('/api/reset-password', async (req, res) => {
    try {
        const { token, newPassword } = req.body;

        if (!token || !newPassword) {
            return res.status(400).json({ error: 'Token and new password are required.' });
        }

        const user = await usersCollection.findOne({
            resetToken: token,
            resetTokenExpires: { $gt: new Date() }
        });

        if (!user) {
            return res.status(400).json({ error: 'Invalid or expired reset link.' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);

        await usersCollection.updateOne(
            { _id: user._id },
            {
                $set: { password: hashedPassword },
                $unset: { resetToken: '', resetTokenExpires: '' }
            }
        );

        return res.status(200).json({ message: 'Password reset successfully. You can now log in.' });
    } catch (err) {
        return res.status(500).json({ error: 'Password reset failed.' });
    }
});
