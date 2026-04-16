import { useState } from "react";
import { useNavigate } from "react-router-dom";
import "../css/authorize.css";

const urlBase = import.meta.env.VITE_API_URL || "http://localhost:5000/api";

function ForgotPassword() {
    const navigate = useNavigate();
    const [message, setMessage] = useState("");
    const [email, setEmail] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [submitted, setSubmitted] = useState(false);

    async function handleSubmit(e: React.FormEvent<HTMLFormElement>): Promise<void> {
        e.preventDefault();
        setMessage("");

        if (!email.trim()) {
            setMessage("Please enter your email address.");
            return;
        }

        setIsLoading(true);

        try {
            const response = await fetch(`${urlBase}/forgot-password`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email: email.trim() }),
            });

            const res = await response.json();
            if (!response.ok) {
                setMessage(res.error || "Server error. Please try again.");
                setIsLoading(false);
                return;
            }

            setIsLoading(false);
            setSubmitted(true);
        } catch (err) {
            console.error("Forgot password error:", err);
            setMessage("Unable to connect to server.");
            setIsLoading(false);
        }
    }

    return (
        <div className="auth-page">
            <div className="overlay">
                <div className="loginbox">
                    <button className="backBtn" onClick={() => navigate("/")}>
                        ←
                    </button>
                    <h1 className="formTitle">FORGOT PASSWORD</h1>

                    {!submitted ? (
                        <form className="form" onSubmit={handleSubmit}>
                            <p className="authSubtext">
                                Enter email associated with account and we will send you a link to reset your password.
                            </p>

                            <label className="field">
                                <span className="labelText">Email</span>
                                <input
                                    className="loginfield"
                                    type="email"
                                    placeholder="Enter your email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                />
                            </label>

                            <button type="submit" className="btn primaryBtn" disabled={isLoading}>
                                {isLoading ? "Sending..." : "Send Reset Link"}
                            </button>

                            <p className="status">{message}</p>
                        </form>
                    ) : (
                        <div className="authConfirm">
                            <p className="authSubtext">
                                If an account exists for <span className="authHighlight">{email}</span>, the
                                password reset link has been sent. Check your email and follow the link.
                            </p>
                            <button className="btn primaryBtn" onClick={() => navigate("/login")}>
                                Back to Login
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

export default ForgotPassword;
