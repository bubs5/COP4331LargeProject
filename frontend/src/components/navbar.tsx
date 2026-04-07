import { Link, useNavigate } from "react-router-dom";

function Navbar() {
    const navigate = useNavigate();

    function handleLogout(): void {
        localStorage.removeItem("user_data");
        navigate("/");
    }

    return (
        <nav className="navbar">
            <h2>StudyRewards</h2>

            <div className="nav-links">
                <Link to="/dashboard">Dashboard</Link>
                <Link to="/flashcards">Study Sets</Link>
                <Link to="/quiz">Quiz</Link>
                <button onClick={handleLogout}>Logout</button>
            </div>
        </nav>
    );
}

export default Navbar;
