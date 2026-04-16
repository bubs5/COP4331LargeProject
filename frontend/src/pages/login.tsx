import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import "../css/authorize.css";

type LoginResponse = {
    id?: string;
    _id?: string;
    firstName: string;
    lastName: string;
    login: string;
    token?: string;
    error?: string;
};

const urlBase = import.meta.env.VITE_API_URL || "http://localhost:5000/api";

function Login() {
    const [message, setMessage] = useState("");
    const [loginName, setLoginName] = useState("");
    const [loginPassword, setLoginPassword] = useState("");
    const [isLoading, setIsLoading] = useState(false);

    const navigate = useNavigate();

    async function doLogin(e: React.FormEvent<HTMLFormElement>): Promise<void> {
        e.preventDefault();
        setMessage("");

        if (!loginName.trim() || !loginPassword.trim()) {
            setMessage("Please enter both username and password.");
            return;
        }

        const obj = {
            login: loginName.trim(),
            password: loginPassword,
        };

        try {
            setIsLoading(true);

            const response = await fetch(`${urlBase}/login`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(obj),
            });

            if (!response.ok) {
                setMessage("Server error. Please try again.");
                setIsLoading(false);
                return;
            }

            const res: LoginResponse = await response.json();

            const userId = res.id || res._id;
            if (!userId || res.error) {
                setMessage(res.error || "User/Password combination incorrect");
                setIsLoading(false);
                return;
            }

            const userData = {
                id: userId,
                firstName: res.firstName,
                lastName: res.lastName,
                username: res.login,
                token: res.token || "",
            };

            localStorage.setItem("user_data", JSON.stringify(userData));

            setLoginName("");
            setLoginPassword("");
            setIsLoading(false);

            navigate("/dashboard");
        } catch (error) {
            console.error("Login error:", error);
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

                    <h1 className="formTitle">LOGIN</h1>

                    <form className="form" onSubmit={doLogin}>
                        <label className="field">
                            <span className="labelText">Username</span>
                            <input
                                className="loginfield"
                                type="text"
                                placeholder="Enter username"
                                value={loginName}
                                onChange={(e) => setLoginName(e.target.value)}
                                required
                            />
                        </label>

                        <label className="field">
                            <span className="labelText">Password</span>
                            <input
                                className="loginfield"
                                type="password"
                                placeholder="Enter password"
                                value={loginPassword}
                                onChange={(e) => setLoginPassword(e.target.value)}
                                required
                            />
                        </label>

                        <p className="forgotText">
                            <Link to="/forgot-password" className="linkBtn">
                                Forgot Password?
                            </Link>
                        </p>

                        <button
                            type="submit"
                            className="btn primaryBtn"
                            disabled={isLoading}
                        >
                            {isLoading ? "Logging In..." : "Login"}
                        </button>

                        <p className="helperText">
                            Don&apos;t have an account?{" "}
                            <Link className="linkBtn" to="/register">
                                Sign up
                            </Link>
                        </p>

                        <p className="status">{message}</p>
                    </form>
                </div>
            </div>
        </div>
    );
}

export default Login;
