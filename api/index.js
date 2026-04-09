require('dotenv').config();
const express = require('express');
const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json()); // Parses Json data
app.use(cors()); // Prevent address conflicts

// Connect to MongoDB
const uri = process.env.MONGODB_URI;
const dbName = 'COP4331Cards';
let db;
let usersCollection;

MongoClient.connect(uri)
    .then(client => {
        db = client.db(dbName);
        usersCollection = db.collection('Users');
        console.log('Connected to the database');
        
        // Start the server
        const port = 5000;
        app.listen(port, () => {
            console.log(`Server is running on port ${port}`);
        });
    })
    .catch(err => {
        console.error('Error connecting to the database', err);
        process.exit(1)
    });



// Registration API
app.post('/api/register', async (req, res) => {
    try{
        // Get the user's information
        const {firstName, lastName, login, email, password} = req.body;

        // Check if the username or email already is in use
        const existingUser = await usersCollection.findOne({
            $or: [{ login }, { email }]
        })

        if (existingUser) {
            return res.status(409).json({ error: "User already exists." });
        }

        // Hash the password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create the user in the database
        const user = {
            firstName,
            lastName,
            login,
            email,
            password: hashedPassword,
            createdAt: new Date()
        };

        await usersCollection.insertOne(user);

        // Success message
        res.status(201).json({ message: "Account created successfully. Please log in." });

    } catch (err) {
        res.status(500).json({ error: "Registration failed." });
    }
});

// Login API
app.post('/api/login', async (req, res) => {
    try {
        // Get the username and password
        const { login, password } = req.body;
        
        // Look for the user in the database
        const user = await usersCollection.findOne({ login: login });

        if (!user) {
            return res.status(401).json({ error: "User/Password combination incorrect" });
        }

        // Compare the recieved password with the password in the database
        const isMatch = await bcrypt.compare(password, user.password);

        if(!isMatch) {
            return res.status(401).json({ error: "User/Password combination incorrect" });
        }

        // Generate the token
        const token = jwt.sign(
            { userId: user._id }, 
                process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        // Send back user info
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

