import "../css/dashboard.css";
import { studySets } from "../data/testData";
import { useNavigate } from "react-router-dom";

function Dashboard() {
    const navigate = useNavigate();
    const lastSet = JSON.parse(localStorage.getItem("lastSet") || "null");

    return (
        <div className="dashboard">
            <h1 className="dashboard-title">Welcome Back</h1>

            <div
                className="dashboard-card"
                onClick={() => {
                    if (lastSet) {
                    navigate(`/flashcards?setId=${lastSet.id}`);                    }
                    }
                }}
                style={{ cursor: lastSet ? "pointer" : "default" }}
            >
                <h2>Recent Activity</h2>

                {lastSet ? (
                    <div>
                        <h3>{lastSet.title}</h3>
                        <p>{lastSet.cardCount} cards</p>
                    </div>
                ) : (
                    <p>No recent activity</p>
                )}
            </div>

            <div className="dashboard-card">
                <div className="section-header">
                    <h2>Your Study Sets</h2>
                    <span
                        className="view-all"
                        onClick={(e) => {
                            e.stopPropagation();
                            navigate("/sets");
                        }}
                    >
                        View All
                    </span>
                </div>

                {studySets.slice(0, 3).map((set) => (           
                   <div
                        key={set.id}
                        className="study-set-preview"
                        onClick={() => {
                            localStorage.setItem("lastSet", JSON.stringify(set));
                            navigate("/flashcards");
                        }}
                        style={{ cursor: "pointer" }}
                    >
                        <h3>{set.title}</h3>
                        <p>{set.description}</p>
                        <p>{set.cardCount} cards</p>
                    </div>
                ))}
            </div>
        </div>
    );
}

export default Dashboard;
