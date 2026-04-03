//test import code before full setup
import { studySets } from '../data/testData';
import { useNavigate } from "react-router-dom";

function StudySets() {

    const navigate = useNavigate();

    return (
        <div>
            <h1>Study Sets</h1>

            {studySets.map((set) => (
                <div
                    key={set.id}
                    className="card"
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
    );
}

export default StudySets;
