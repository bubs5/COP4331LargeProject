import { Routes, Route } from "react-router-dom";
import Navbar from './components/navbar';
import Home from './pages/home';
import Login from './pages/login';
import Register from './pages/register';
import Dashboard from './pages/dashboard';
import Sets from './pages/sets';
import Flashcards from './pages/flashcards';
import Quiz from './pages/quiz';

function App() {
    return (
        <>
            <Navbar />
            <div className="container">
                <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/login" element={<Login />} />
                    <Route path="/register" element={<Register />} />
                    <Route path="/dashboard" element={<Dashboard />} />
                    <Route path="/sets" element={<Sets />} />
                    <Route path="/flashcards" element={<Flashcards />} />
                    <Route path="/quiz" element={<Quiz />} />
                </Routes>
            </div>
        </>
    );
}

export default App;