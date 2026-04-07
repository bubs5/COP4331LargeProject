import { useEffect, useState } from "react";
import "../css/dashboard.css";
import { getStudySets } from "../services/setsService";
import type { StudySet } from "../types";
import { useNavigate } from "react-router-dom";

function Dashboard() {
    const navigate = useNavigate();
    const lastSet = JSON.parse(localStorage.getItem("lastSet") || "null");

    const [sets, setSets] = useState<StudySet[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function loadSets() {
            try {
                const fetched = await getStudySets();
                setSets(fetched);
            } catch (err) {
                console.error("Failed to load sets for dashboard:", err);
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
                    if (lastSet) {
                        navigate("/flashcards");
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

                {loading ? (
                    <p>Loading sets...</p>
                ) : sets.length === 0 ? (
                    <p>No study sets yet. Create one!</p>
                ) : (
                    sets.slice(0, 3).map((set) => (
                        <div
                            key={set.id}
                            className="study-set-preview"
                            onClick={() => {
                                localStorage.setItem("lastSet", JSON.stringify(set));
                                navigate(`/flashcards?setId=${set.id}`);
                            }}
                            style={{ cursor: "pointer" }}
                        >
                            <h3>{set.title}</h3>
                            <p>{set.description}</p>
                            <p>{set.cardCount} cards</p>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}

export default Dashboard;
