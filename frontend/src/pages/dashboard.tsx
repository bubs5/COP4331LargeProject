import "../css/dashboard.css";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import type { StudySet } from "../types";
import { getStudySets } from "../services/setsService";

function Dashboard() {
    const navigate = useNavigate();
    const lastSet = JSON.parse(localStorage.getItem("lastSet") || "null");

    const [sets, setSets] = useState<StudySet[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

    useEffect(() => {
        async function loadSets() {
            try {
                setLoading(true);
                setError("");
                const data = await getStudySets();
                setSets(data);
            } catch (err) {
                console.error(err);
                setError("Failed to load study sets.");
            } finally {
                setLoading(false);
            }
        }

        loadSets();
    }, []);

    return (
        <div className="dashboard">
            <h1 className="dashboard-title">Welcome Back</h1>

            <div
                className="dashboard-card"
                onClick={() => {
                    if (lastSet?.id) {
                        navigate(`/flashcards?setId=${lastSet.id}`);
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
                    <h2>Your Sets</h2>
                    <span
                        className="view-all"
                        onClick={(e) => {
                            e.stopPropagation();
                            navigate("/flashcards");
                        }}
                    >
                        View All
                    </span>
                </div>

                {loading ? (
                    <p>Loading study sets...</p>
                ) : error ? (
                    <p>{error}</p>
                ) : sets.length === 0 ? (
                    <p>No study sets yet.</p>
                ) : (
                    <div className="dashboard-sets-list">
    {sets.slice(0, 3).map((set) => (
        <div
            key={set.id}
            className="dashboard-set-row"
            onClick={() => {
                localStorage.setItem("lastSet", JSON.stringify(set));
                navigate(`/sets/${set.id}`);
            }}
            style={{ cursor: "pointer" }}
        >
            <div className="dashboard-set-copy">
                <h3>{set.title}</h3>
                <p>{set.description}</p>
            </div>

            <span className="dashboard-set-count">
                {set.cardCount} cards
            </span>
        </div>
    ))}
</div>
                )}
            </div>
        </div>
    );
}

export default Dashboard;
