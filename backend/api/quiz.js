const { ObjectId } = require('mongodb');

exports.setApp = function (app, client) {

    // POST /api/quiz/start
    app.post('/api/quiz/start', async (req, res) => {
        const { setId, userId } = req.body;

        if (!setId || !userId) {
            return res.status(400).json({ error: 'setId and userId are required.' });
        }

        try {
            const db = client.db('quizapp');
            const set = await db.collection('Sets').findOne({ _id: new ObjectId(setId) });

            if (!set) {
                return res.status(404).json({ error: 'Study set not found.' });
            }

            const cards = await db.collection('Cards')
                .find({ setId: setId })
                .toArray();

            if (cards.length === 0) {
                return res.status(400).json({ error: 'This set has no cards to quiz.' });
            }

            const shuffled = cards.sort(() => Math.random() - 0.5);

            const session = {
                userId,
                setId,
                setTitle: set.title,
                cards: shuffled.map(c => ({ cardId: c._id.toString(), term: c.term, definition: c.definition })),
                totalCards: shuffled.length,
                correct: 0,
                incorrect: 0,
                answeredCards: [],
                completed: false,
                startedAt: new Date().toISOString(),
            };

            const result = await db.collection('QuizSessions').insertOne(session);

            return res.status(201).json({
                sessionId: result.insertedId,
                cards: session.cards,
                totalCards: session.totalCards,
                error: '',
            });

        } catch (e) {
            console.error('Quiz start error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });

    // POST /api/quiz/answer
    app.post('/api/quiz/answer', async (req, res) => {
        const { sessionId, cardId, userAnswer } = req.body;

        if (!sessionId || !cardId || userAnswer === undefined) {
            return res.status(400).json({ error: 'sessionId, cardId, and userAnswer are required.' });
        }

        try {
            const db = client.db('quizapp');
            const sessions = db.collection('QuizSessions');
            const session = await sessions.findOne({ _id: new ObjectId(sessionId) });

            if (!session) {
                return res.status(404).json({ error: 'Session not found.' });
            }

            const card = session.cards.find(c => c.cardId === cardId);

            if (!card) {
                return res.status(404).json({ error: 'Card not found in session.' });
            }

            const isCorrect =
                userAnswer.trim().toLowerCase() === card.definition.trim().toLowerCase();

            const update = {
                $push: { answeredCards: { cardId, userAnswer, isCorrect } },
                $inc: {
                    correct: isCorrect ? 1 : 0,
                    incorrect: isCorrect ? 0 : 1,
                },
            };

            const answered = session.answeredCards.length + 1;
            if (answered >= session.totalCards) {
                update.$set = { completed: true, completedAt: new Date().toISOString() };
            }

            await sessions.updateOne({ _id: new ObjectId(sessionId) }, update);

            return res.status(200).json({
                correct: isCorrect,
                correctAnswer: card.definition,
                progress: { answered, total: session.totalCards },
                error: '',
            });

        } catch (e) {
            console.error('Quiz answer error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });

    // GET /api/quiz/results/:sessionId
    app.get('/api/quiz/results/:sessionId', async (req, res) => {
        const { sessionId } = req.params;

        try {
            const db = client.db('quizapp');
            const session = await db.collection('QuizSessions').findOne({
                _id: new ObjectId(sessionId)
            });

            if (!session) {
                return res.status(404).json({ error: 'Session not found.' });
            }

            const score = Math.round((session.correct / session.totalCards) * 100);

            return res.status(200).json({
                setTitle: session.setTitle,
                totalCards: session.totalCards,
                correct: session.correct,
                incorrect: session.incorrect,
                score,
                answeredCards: session.answeredCards,
                error: '',
            });

        } catch (e) {
            console.error('Quiz results error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });

    // GET /api/quiz/history/:userId
    app.get('/api/quiz/history/:userId', async (req, res) => {
        const { userId } = req.params;

        try {
            const db = client.db('quizapp');
            const sessions = await db.collection('QuizSessions')
                .find({ userId, completed: true })
                .sort({ completedAt: -1 })
                .toArray();

            const summary = sessions.map(s => ({
                sessionId: s._id,
                setTitle: s.setTitle,
                totalCards: s.totalCards,
                correct: s.correct,
                score: Math.round((s.correct / s.totalCards) * 100),
                completedAt: s.completedAt,
            }));

            return res.status(200).json({ sessions: summary, error: '' });

        } catch (e) {
            console.error('Quiz history error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });
};
