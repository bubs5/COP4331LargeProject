import { Link } from "react-router-dom";
import "../css/authorize.css";

function Home() {
    return (
        <main className="home-container">
            <div className="home-content">
                <h1 className="home-title">StudyRewards</h1>

                <p className="home-description">
                    Study with flashcards, take quizzes, and earn rewards while you study.
                </p>

                <div className="home-buttons">
                    <Link to="/login" className="home-btn">
                        Login
                    </Link>

                    <Link to="/register" className="home-btn secondary">
                        Register
                    </Link>
                </div>
            </div>
        </main>
    );
}

export default Home;
