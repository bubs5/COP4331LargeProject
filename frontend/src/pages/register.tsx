//bottom has code for when api is ready
import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import "../css/authorize.css";

type RegisterResponse = {
    error?: string;
    message?: string;
};

function Register() {
    const navigate = useNavigate();

    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [username, setUsername] = useState("");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");

    const [message, setMessage] = useState("");
    const [isLoading, setIsLoading] = useState(false);

    async function handleRegister(
        e: React.FormEvent<HTMLFormElement>
    ): Promise<void> {
        e.preventDefault();
        setMessage("");

        if (
            !firstName.trim() ||
            !lastName.trim() ||
            !username.trim() ||
            !email.trim() ||
            !password ||
            !confirmPassword
        ) {
            setMessage("Please fill in all fields.");
            return;
        }

        if (password !== confirmPassword) {
            setMessage("Passwords do not match.");
            return;
        }

        const obj = {
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            login: username.trim(),
            email: email.trim(),
            password: password,
        };

        try {
            setIsLoading(true);

            const response = await fetch("http://localhost:5000/api/register", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(obj),
            });

            if (!response.ok) {
                setMessage("Server error. Please try again.");
                setIsLoading(false);
                return;
            }

            const res: RegisterResponse = await response.json();

            if (res.error && res.error.length > 0) {
                setMessage(res.error);
                setIsLoading(false);
                return;
            }

            setMessage(
                res.message || "Account created successfully. Please log in."
            );

            setFirstName("");
            setLastName("");
            setUsername("");
            setEmail("");
            setPassword("");
            setConfirmPassword("");
            setIsLoading(false);

            setTimeout(() => {
                navigate("/login");
            }, 1500);
        } catch (error) {
            console.error("Register error:", error);
            setMessage("Unable to connect to server.");
            setIsLoading(false);
        }
    }

    return (
        <div className="auth-page">
            <div className="overlay">
                <div className="loginbox">
                    <button
                        type="button"
                        className="backBtn"
                        onClick={() => navigate("/")}
                    >
                        ←
                    </button>

                    <h1 className="formTitle">SIGN UP</h1>

                    <form className="form" onSubmit={handleRegister}>
                        <label className="field">
                            <span className="labelText">First Name</span>
                            <input
                                className="loginfield"
                                type="text"
                                placeholder="Enter first name"
                                value={firstName}
                                onChange={(e) => setFirstName(e.target.value)}
                                required
                            />
                        </label>

                        <label className="field">
                            <span className="labelText">Last Name</span>
                            <input
                                className="loginfield"
                                type="text"
                                placeholder="Enter last name"
                                value={lastName}
                                onChange={(e) => setLastName(e.target.value)}
                                required
                            />
                        </label>

                        <label className="field">
                            <span className="labelText">Username</span>
                            <input
                                className="loginfield"
                                type="text"
                                placeholder="Create username"
                                value={username}
                                onChange={(e) => setUsername(e.target.value)}
                                required
                            />
                        </label>

                        <label className="field">
                            <span className="labelText">Email</span>
                            <input
                                className="loginfield"
                                type="email"
                                placeholder="Enter email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </label>

                        <label className="field">
                            <span className="labelText">Password</span>
                            <input
                                className="loginfield"
                                type="password"
                                placeholder="Create password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </label>

                        <label className="field">
                            <span className="labelText">Confirm Password</span>
                            <input
                                className="loginfield"
                                type="password"
                                placeholder="Confirm password"
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                                required
                            />
                        </label>

                        <button type="submit" className="btn primaryBtn" disabled={isLoading}>
                            {isLoading ? "Creating Account..." : "Create Account"}
                        </button>

                        <p className="helperText">
                            Already have an account?{" "}
                            <Link className="linkBtn" to="/login">
                                Login
                            </Link>
                        </p>

                        <p className="status">{message}</p>
                    </form>
                </div>
            </div>
        </div>
    );
}

export default Register;

