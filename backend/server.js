require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();
app.use(cors());
app.use(express.json());

const uri = process.env.MONGODB_URI;
const client = new MongoClient(uri);

async function startServer() {
    try {
        await client.connect();
        console.log('Connected to MongoDB');

        const authRouter = require('./api/auth');
        const quizRouter = require('./api/quiz');

        authRouter.setApp(app, client);
        quizRouter.setApp(app, client);

        const port = process.env.PORT || 5000;
        app.listen(port, () => {
            console.log(`Server running on port ${port}`);
        });

    } catch (err) {
        console.error('Failed to connect to MongoDB:', err);
        process.exit(1);
    }
}

startServer();
