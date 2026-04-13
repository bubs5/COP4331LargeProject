import { Link, useNavigate } from "react-router-dom";
import { useRewards } from "../context/RewardsContext";
import "../css/navbar.css";

function Navbar() {
    const navigate = useNavigate();
    const { rewards } = useRewards();

    function handleLogout(): void{
        localStorage.removeItem("user_data");
        navigate("/");
    }

    return(
        <nav className="navbar">
            <h2>StudyRewards</h2>

            <div className="nav-links">
                <Link to="/dashboard">Dashboard</Link>
                <Link to="/flashcards">Study Sets</Link>

                {/*points pill → rewards page */}
                <Link to="/rewards" className="nav-points-pill">
                     {rewards.totalPoints.toLocaleString()} pts
                </Link>

                <button className="secondary-btn" onClick={handleLogout}>
                    Logout
                </button>
            </div>
        </nav>
    );
}

export default Navbar;
