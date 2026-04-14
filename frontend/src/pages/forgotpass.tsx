import { useNavigate } from "react-router-dom";

function ForgotPassword() {
    const navigate = useNavigate();

    return (
        <div className="auth-page">
            <div className="overlay">
                <div className="loginbox">
                    <button className="backBtn" onClick={() => navigate("/login")}>
                        ←
                    </button>

                    <h1 className="formTitle">Forgot Password</h1>

                    <p style={{ textAlign: "center" }}>
                        Will work when code is added later
                    </p>
                </div>
            </div>
        </div>
    );
}

export default ForgotPassword;