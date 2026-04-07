import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "../css/sets.css";
import type { StudySet } from "../types";
import { getStudySets, createStudySet, deleteStudySet } from "../services/setsService";

function Sets() {
    const navigate = useNavigate();

    const [sets, setSets] = useState<StudySet[]>([]);
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");


    //data fetching
    //fetches the full list of differnt study sets
    async function loadSets(){
        try {
            setLoading(true);
            const data = await getStudySets();
            setSets(data);
        } catch (err) {
            console.error(err);
            setError("Failed to load study sets.");
        } finally {
            setLoading(false);
        }
    }

    useEffect(() =>{
        loadSets();
    }, []);

    //create a new set

    async function handleCreateSet(e: React.FormEvent){
        e.preventDefault();
        //both fields are required to be filled
        if (!title.trim() || !description.trim()) return;

        try{
            const newSet = await createStudySet({
                title,
                description,
            });

            setTitle("");
            setDescription("");
            await loadSets();

            navigate(`/sets/${newSet.id}`);
        } catch (err){
            console.error(err);
            setError("Failed to create set.");
        }
    }

    //delete a set
    async function handleDeleteSet(setId: string){
        const confirmed = window.confirm("Delete this study set?");
        if (!confirmed) return;

        try{
            await deleteStudySet(setId);
            await loadSets();
        } catch (err) {
            console.error(err);
            setError("Failed to delete set.");
        }
    }

    if (loading){
        return <div className="page-state">Loading study sets...</div>;
    }

    return(
        <div className="sets-page">
            <div className="sets-header">
                <div>
                    <p className="eyebrow">Study Sets</p>
                    <h1>Your Sets</h1>

                </div>
            </div>

            {error && <div className="page-state error-state">{error}</div>}

            <section className="sets-list-section">
                {sets.length === 0 ? (
                    <div className="empty-card">
                        <h2>No sets yet</h2>
                        <p>Create your first study set below.</p>
                    </div>
                ) : (
                    <div className="sets-grid">
                        {sets.map((set) =>(
                            <div
                                key={set.id}
                                className="set-card"
                                onClick={() => navigate(`/sets/${set.id}`)}
                            >
                                <div className="set-card-top">
                                    <div>
                                        <h3>{set.title}</h3>
                                        <p>{set.description}</p>
                                    </div>
                                    <span className="card-badge">{set.cardCount} cards</span>
                                </div>

                                <div className="set-card-actions">
                                    <button
                                        className="secondary-btn"
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            navigate(`/sets/${set.id}`);
                                        }}
                                    >
                                        Open
                                    </button>

                                    <button
                                        className="danger-btn"
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            handleDeleteSet(set.id);
                                        }}
                                    >
                                        Delete
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </section>

            <section className="create-set-section">
                <h2>Create New Set</h2>

                <form onSubmit={handleCreateSet} className="set-form">
                    <label>Set title</label>
                    <input
                        type="text"
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        placeholder="Ex. Math Chapter 5"
                    />

                    <label>Description</label>
                    <textarea
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                        placeholder="What is this set for?"
                    />

                    <button className="primary-btn" type="submit">
                        Create Set
                    </button>
                </form>
            </section>
        </div>
    );
}

export default Sets;