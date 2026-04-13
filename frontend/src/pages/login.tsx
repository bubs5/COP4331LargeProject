//for testing
//code for when api is ready

import { useState } from "react";
import {Link, useNavigate} from "react-router-dom";
import { mockUsers } from "../data/testData";
import "../css/authorize.css";


function Login() {
    const [message, setMessage] = useState("");
    const [loginName, setLoginName] = useState("");
    const [loginPassword, setLoginPassword] = useState("");

    const navigate = useNavigate();

    //will change when API is ready
    function doLogin(e: React.FormEvent<HTMLFormElement>): void {
        e.preventDefault();

        const foundUser = mockUsers.find(
            (user) =>
                user.username === loginName.trim() &&
                user.password === loginPassword.trim()
        );

        if (!foundUser) {
            setMessage("User/Password combination incorrect");
            return;
        }

        const userData = {
            id: foundUser.id,
            firstName: foundUser.firstName,
            lastName: foundUser.lastName,
            username: foundUser.username,
        };

        localStorage.setItem("user_data", JSON.stringify(userData));
        setMessage("");
        navigate("/dashboard");
    }

    return (
        <div className="auth-page">
            <div className="overlay">
                <div className="loginbox">
                    <button className="backBtn" onClick={() => navigate("/")}>
                        ←
                    </button>

                    <h1 className="formTitle">LOGIN</h1>

                    <form className="form" onSubmit={doLogin}>
                        <label className="field">
                            <span className="labelText">Login</span>
                            <input
                                className="loginfield"
                                type="text"
                                placeholder="Username"
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
                                placeholder="Password"
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
                        <button type="submit" className="btn primaryBtn">
                            Login
                        </button>

                        <p className="helperText">
                            Don’t have an account?{" "}
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







//same file but with API components
/*
import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import "../styles/auth.css";

type LoginResponse = {
  id: number;
  firstName: string;
  lastName: string;
  login: string;
  token?: string;
  error?: string;
};

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
        //replace with API link when ready
      const response = await fetch("http://localhost:5000/api/login", {
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

      const res: LoginResponse = await response.json();

      if (!res.id || res.id <= 0) {
        setMessage(res.error || "User/Password combination incorrect");
        setIsLoading(false);
        return;
      }

      const userData = {
        id: res.id,
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

            <button type="submit" className="btn primaryBtn" disabled={isLoading}>
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
*/