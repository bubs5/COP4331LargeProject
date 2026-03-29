import { Routes, Route, useLocation } from "react-router-dom";
import Navbar from "./components/navbar";
import Home from "./pages/home";
import Login from "./pages/login";
import Register from "./pages/register";
import ForgotPassword from "./pages/forgotpass";
import Dashboard from "./pages/dashboard";
import StudySets from "./pages/sets";
import Flashcards from "./pages/flashcards";
import Quiz from "./pages/quiz";

function App() {
    const location = useLocation();
    const user = localStorage.getItem("user_data");

    const hideNavbarRoutes = ["/", "/login", "/register"];
    const showNavbar = !!user && !hideNavbarRoutes.includes(location.pathname);

    return (
        <>
            {showNavbar && <Navbar />}

            <div className="container">
                <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/login" element={<Login />} />
                    <Route path="/register" element={<Register />} />
                    <Route path="/forgot-password" element={<ForgotPassword />} />
                    <Route path="/dashboard" element={<Dashboard />} />
                    <Route path="/sets" element={<StudySets />} />
                    <Route path="/flashcards" element={<Flashcards />} />
                    <Route path="/quiz" element={<Quiz />} />
                </Routes>
            </div>
        </>
    );
}

export default App;