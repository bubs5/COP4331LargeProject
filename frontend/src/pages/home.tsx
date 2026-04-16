import { Link } from "react-router-dom";
import "../css/authorize.css";

function Home() {
    return (
        <div className="home-container">
            <div className="home-content">
                <h1 className="home-title">StudyRewards</h1>

                <p className="home-description">
                    Study with flashcards, take quizzes, and earn rewards while you study.
                </p>

                <div className="home-buttons">
                    <Link to="/login">
                        <button className="home-btn">Login</button>
                    </Link>

                    <Link to="/register">
                        <button className="home-btn secondary">Register</button>
                    </Link>
                </div>
            </div>
        </div>
    );
}

export default Home;