import { useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import "../css/authorize.css";

type ResetPasswordResponse = {
    error?: string;
    message?: string;
};

const urlBase = import.meta.env.VITE_API_URL || "http://localhost:5000/api";

function ResetPassword() {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const token = searchParams.get("token");

    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [message, setMessage] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [success, setSuccess] = useState(false);

    async function handleSubmit(e: React.FormEvent<HTMLFormElement>): Promise<void> {
        e.preventDefault();
        setMessage("");

        if (!password || !confirmPassword) {
            setMessage("Please fill in all fields.");
            return;
        }

        if (password !== confirmPassword) {
            setMessage("Passwords do not match.");
            return;
        }

        if (password.length < 6) {
            setMessage("Password must be at least 6 characters.");
            return;
        }

        if (!token) {
            setMessage("Invalid or missing reset token. Please request a new reset link.");
            return;
        }

        setIsLoading(true);

        try {
            const response = await fetch(`${urlBase}/reset-password`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ token, newPassword: password }),
            });
            const res: ResetPasswordResponse = await response.json();

            if (!response.ok || (res.error && res.error.length > 0)) {
                setMessage(res.error || "Server error. Please try again.");
                setIsLoading(false);
                return;
            }

            setIsLoading(false);
            setSuccess(true);

            setTimeout(() => {
                navigate("/login");
            }, 2500);
        } catch (err) {
            console.error("Reset password error:", err);
            setMessage("Unable to connect to server.");
            setIsLoading(false);
        }
    }

    if (!token) {
        return (
            <div className="auth-page">
                <div className="overlay">
                    <div className="loginbox">
                        <h1 className="formTitle">RESET PASSWORD</h1>
                        <p className="statusError">
                            Invalid or expired reset link. Please try again.
                        </p>
                        <button className="btn primaryBtn" onClick={() => navigate("/forgot-password")}>
                            Request New Link
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="auth-page">
            <div className="overlay">
                <div className="loginbox">
                    <button className="backBtn" onClick={() => navigate("/login")}>
                        ←
                    </button>

                    <h1 className="formTitle">RESET PASSWORD</h1>

                    {!success ? (
                        <form className="form" onSubmit={handleSubmit}>
                            <label className="field">
                                <span className="labelText">New Password</span>
                                <input
                                    className="loginfield"
                                    type="password"
                                    placeholder="Enter new password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                />
                            </label>

                            <label className="field">
                                <span className="labelText">Confirm New Password</span>
                                <input
                                    className="loginfield"
                                    type="password"
                                    placeholder="Confirm new password"
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                    required
                                />
                            </label>

                            <button type="submit" className="btn primaryBtn" disabled={isLoading}>
                                {isLoading ? "Resetting..." : "Reset Password"}
                            </button>

                            <p className="status">{message}</p>
                        </form>
                    ) : (
                        <div className="authConfirm">
                            <p className="statusSuccess">
                                Your password has been reset successfully. Redirecting to login.
                            </p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

export default ResetPassword;
