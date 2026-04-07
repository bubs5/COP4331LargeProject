import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "../css/sets.css";
import {  createStudySet } from "../services/setsService";

function Sets() {
    const navigate = useNavigate();

    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [error, setError] = useState("");

  
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

            navigate(`/sets/${newSet.id}`);
        } catch (err){
            console.error(err);
            setError("Failed to create set.");
        }
    }

   
    return (
        <div className="sets-page">
            <div className="sets-header">
                <div>
                    <p className="eyebrow">Study Sets</p>
                    <h1>Create New Set</h1>
                </div>
            </div>

            {error && <div className="page-state error-state">{error}</div>}

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
