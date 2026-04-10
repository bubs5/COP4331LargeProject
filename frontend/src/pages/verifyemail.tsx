import {useState, useEffect} from "react";
import {useNavigate, useSearchParams} from "react-router-dom";
import "../css/authorize.css";

type VerifyEmailResponse = {
    error?: string;
    message?: string;
};

function VerifyEmail(){
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const token = searchParams.get("token");

    const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
    const [message, setMessage] = useState("");

    useEffect(() =>{
        async function verifyToken() {
            if (!token){
                setStatus("error");
                setMessage("Invalid or missing verification link. Please register again.");
                return;
            }

            //replace with API link when ready
            try {
                const response = await fetch("http://localhost:5000/api/verify-email", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({token}),
                });

                const res: VerifyEmailResponse = await response.json();
                if (!response.ok || (res.error && res.error.length > 0)) {
                    setStatus("error");
                    setMessage(res.error || "Verification failed. The link may have expired.");
                    return;
                }

                setStatus("success");
                setMessage(res.message || "Email verified successfully!");
            }
            catch{
                setStatus("error");
                setMessage("Unable to connect to server.");
            }

            setStatus("success");
            setMessage("Email verified successfully!");
        }
        verifyToken();
    }, [token]);


    return (
        <div className="auth-page">
            <div className="overlay">
                <div className="loginbox">
                    <h1 className="formTitle">EMAIL VERIFICATION</h1>

                    {status === "loading" && (
                        <p className="authSubtext">Verifying your email...</p>
                    )}

                    {status === "success" && (
                        <div className="authConfirm">
                            <p className="statusSuccess">✓ {message}</p>
                            <p className="helperText">You can now log in to your account.</p>
                            <button className="btn primaryBtn" onClick={() => navigate("/login")}>
                                Go to Login
                            </button>
                        </div>
                    )}

                    {status === "error" && (
                        <div className="authConfirm">
                            <p className="statusError">{message}</p>
                            <button className="btn primaryBtn" onClick={() => navigate("/register")}>
                                Back to Sign Up
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

export default VerifyEmail;


