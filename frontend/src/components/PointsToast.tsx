import { useRewards } from "../context/RewardsContext";
import "../css/pointsToast.css";

export default function PointsToast(){
    const { toast, dismissToast } = useRewards();

    if (!toast) return null;

    return (
        <div className="points-toast" onClick={dismissToast} key={toast.id}>
            <span className="points-toast-icon">{toast.icon}</span>
            <div className="points-toast-body">
                <span className="points-toast-label">{toast.label}</span>
                <span className="points-toast-pts">+{toast.points} pts</span>
            </div>
        </div>
    );
}
