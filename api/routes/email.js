require('dotenv').config();
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

const sendVerificationEmail = async (userEmail, verificationToken) => {
    try {
      const verificationUrl = `${process.env.BASE_URL}/verify-email?token=${verificationToken}`;
  
      const mailOptions = {
        from: `<${process.env.EMAIL_USER}>`,
        to: userEmail,                                         // Recipient address
        subject: 'Please Verify Your Email Address',           // Subject line
        text: `Welcome to StudyRewards! Please verify your email by clicking this link: ${verificationUrl}`,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Welcome to My App!</h2>
            <p>Thank you for signing up. Please verify your email address by clicking the button below:</p>
            <a href="${verificationUrl}" style="background-color:rgb(16, 24, 243); color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Verify Email</a>
            <p>If the button doesn't work, you can also click this link:</p>
            <p><a href="${verificationUrl}">${verificationUrl}</a></p>
          </div>
        `,
      };

      const info = await transporter.sendMail(mailOptions);
      console.log('Verification email sent successfully:', info.messageId);
      return true;
  
    } catch (error) {
      console.error('Error sending verification email:', error);
      throw new Error('Could not send verification email');
    }
  };

const sendPasswordResetEmail = async (userEmail, resetToken) => {
    try {
      const resetUrl = `${process.env.BASE_URL}/reset-password?token=${resetToken}`;

      const mailOptions = {
        from: `<${process.env.EMAIL_USER}>`,
        to: userEmail,
        subject: 'Reset Your Password',
        text: `You requested a password reset. Click this link to reset your password: ${resetUrl}`,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Password Reset Request</h2>
            <p>We received a request to reset your password.</p>
            <a href="${resetUrl}" style="background-color:rgb(16, 24, 243); color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
            <p>If the button doesn't work, use this link:</p>
            <p><a href="${resetUrl}">${resetUrl}</a></p>
            <p>This link expires in 1 hour.</p>
          </div>
        `,
      };

      const info = await transporter.sendMail(mailOptions);
      console.log('Password reset email sent successfully:', info.messageId);
      return true;
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error('Could not send password reset email');
    }
};
  
module.exports = { sendVerificationEmail, sendPasswordResetEmail };
