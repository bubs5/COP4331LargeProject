//test import code before full setup
import { studySets } from '../data/testData';

function StudySets() {
    return (
        <div>
            <h1>Study Sets</h1>

            {studySets.map((set) => (
                <div key={set.id} className="card">
                    <h3>{set.title}</h3>
                    <p>{set.description}</p>
                    <p>{set.cardCount} cards</p>
                </div>
            ))}
        </div>
    );
}

export default StudySets;