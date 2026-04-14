const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

exports.setApp = function (app, client) {

    // POST /api/register
    app.post('/api/register', async (req, res) => {
        const { firstName, lastName, login, email, password } = req.body;

        if (!firstName || !lastName || !login || !email || !password) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        try {
            const db = client.db('quizapp');
            const users = db.collection('Users');

            const existingUser = await users.findOne({
                $or: [{ login: login }, { email: email }]
            });

            if (existingUser) {
                return res.status(409).json({ error: 'Username or email already in use.' });
            }

            const hashedPassword = await bcrypt.hash(password, 10);
            const verifyToken = crypto.randomBytes(32).toString('hex');

            const newUser = {
                firstName, lastName, login, email,
                password: hashedPassword,
                isVerified: false,
                verifyToken,
                createdAt: new Date().toISOString(),
            };

            await users.insertOne(newUser);
            await sendVerificationEmail(email, verifyToken);

            return res.status(201).json({
                message: 'Account created. Please check your email to verify your account.'
            });

        } catch (e) {
            console.error('Register error:', e);
            return res.status(500).json({ error: 'Server error. Please try again.' });
        }
    });

    // GET /api/verify/:token
    app.get('/api/verify/:token', async (req, res) => {
        const { token } = req.params;

        try {
            const db = client.db('quizapp');
            const users = db.collection('Users');
            const user = await users.findOne({ verifyToken: token });

            if (!user) {
                return res.status(400).json({ error: 'Invalid or expired verification link.' });
            }

            await users.updateOne(
                { verifyToken: token },
                { $set: { isVerified: true }, $unset: { verifyToken: '' } }
            );

            return res.status(200).json({ message: 'Email verified. You can now log in.' });

        } catch (e) {
            console.error('Verify error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });

    // POST /api/login
    app.post('/api/login', async (req, res) => {
        const { login, password } = req.body;

        if (!login || !password) {
            return res.status(400).json({ error: 'Login and password are required.' });
        }

        try {
            const db = client.db('quizapp');
            const users = db.collection('Users');
            const user = await users.findOne({ login: login });

            if (!user) {
                return res.status(401).json({ error: 'User/Password combination incorrect.' });
            }

            if (!user.isVerified) {
                return res.status(403).json({ error: 'Please verify your email before logging in.' });
            }

            const passwordMatch = await bcrypt.compare(password, user.password);

            if (!passwordMatch) {
                return res.status(401).json({ error: 'User/Password combination incorrect.' });
            }

            const token = jwt.sign(
                { id: user._id, login: user.login },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            return res.status(200).json({
                id: user._id,
                firstName: user.firstName,
                lastName: user.lastName,
                login: user.login,
                token,
                error: '',
            });

        } catch (e) {
            console.error('Login error:', e);
            return res.status(500).json({ error: 'Server error. Please try again.' });
        }
    });

    // POST /api/forgot-password
    app.post('/api/forgot-password', async (req, res) => {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ error: 'Email is required.' });
        }

        try {
            const db = client.db('quizapp');
            const users = db.collection('Users');
            const user = await users.findOne({ email: email });

            if (!user) {
                return res.status(200).json({ message: 'If that email exists, a reset link has been sent.' });
            }

            const resetToken = crypto.randomBytes(32).toString('hex');
            const resetExpiry = new Date(Date.now() + 3600000);

            await users.updateOne(
                { email: email },
                { $set: { resetToken, resetExpiry } }
            );

            await sendPasswordResetEmail(email, resetToken);

            return res.status(200).json({ message: 'If that email exists, a reset link has been sent.' });

        } catch (e) {
            console.error('Forgot password error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });

    // POST /api/reset-password
    app.post('/api/reset-password', async (req, res) => {
        const { token, newPassword } = req.body;

        if (!token || !newPassword) {
            return res.status(400).json({ error: 'Token and new password are required.' });
        }

        try {
            const db = client.db('quizapp');
            const users = db.collection('Users');

            const user = await users.findOne({
                resetToken: token,
                resetExpiry: { $gt: new Date() }
            });

            if (!user) {
                return res.status(400).json({ error: 'Invalid or expired reset link.' });
            }

            const hashedPassword = await bcrypt.hash(newPassword, 10);

            await users.updateOne(
                { resetToken: token },
                {
                    $set: { password: hashedPassword },
                    $unset: { resetToken: '', resetExpiry: '' }
                }
            );

            return res.status(200).json({ message: 'Password reset successfully. You can now log in.' });

        } catch (e) {
            console.error('Reset password error:', e);
            return res.status(500).json({ error: 'Server error.' });
        }
    });
};

async function sendVerificationEmail(toEmail, token) {
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
    });

    const verifyUrl = `http://localhost:5000/api/verify/${token}`;
    await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: toEmail,
        subject: 'Verify your account',
        html: `<p>Click the link below to verify your account:</p><a href="${verifyUrl}">${verifyUrl}</a>`,
    });
}

async function sendPasswordResetEmail(toEmail, token) {
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
    });

    const resetUrl = `http://localhost:3000/reset-password?token=${token}`;
    await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: toEmail,
        subject: 'Password Reset Request',
        html: `<p>Click the link below to reset your password (expires in 1 hour):</p><a href="${resetUrl}">${resetUrl}</a>`,
    });
}
