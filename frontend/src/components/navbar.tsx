import {Link} from 'react-router-dom';

function Navbar() {
    return (
        <nav className="navbar">
            <h2>COP4331 large project</h2>
            <div className="nav-links">
                <Link to="/">Home</Link>
                <Link to="/dashboard">Dashboard</Link>
                <Link to="/sets">Study Sets</Link>                <Link to="/flashcards">Flashcards</Link>
                <Link to="/quiz">Quiz</Link>
                <Link to="/login">Login</Link>
            </div>
        </nav>
    );
}

export default Navbar;