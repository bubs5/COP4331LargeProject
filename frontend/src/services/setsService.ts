import type { Flashcard, StudySet } from '../types';

const urlBase = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

// Helper to get the stored user data (for userId and token)
function getUserData(): { id: string; token: string } | null {
    const raw = localStorage.getItem('user_data');
    if (!raw) return null;
    try {
        const parsed = JSON.parse(raw);
        return { id: parsed.id, token: parsed.token || '' };
    } catch {
        return null;
    }
}

// Helper to build auth headers
function authHeaders(): Record<string, string> {
    const user = getUserData();
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (user?.token) {
        headers['Authorization'] = `Bearer ${user.token}`;
    }
    return headers;
}

// Maps a raw API set object (with _id) to the frontend StudySet shape
function mapSet(raw: any): StudySet {
    return {
        id: raw._id || raw.id,
        title: raw.title,
        description: raw.description,
        cardCount: raw.cardCount ?? 0,
        createdAt: raw.createdAt,
        updatedAt: raw.updatedAt,
    };
}

// Maps a raw API card object (with _id) to the frontend Flashcard shape
function mapCard(raw: any): Flashcard {
    return {
        id: raw._id || raw.id,
        term: raw.term,
        definition: raw.definition,
        setId: raw.setId,
    };
}

// ─── Study Sets ───────────────────────────────────────────────

export async function getStudySets(): Promise<StudySet[]> {
    const user = getUserData();
    const url = user ? `${urlBase}/sets?userId=${user.id}` : `${urlBase}/sets`;

    const response = await fetch(url, { headers: authHeaders() });
    if (!response.ok) throw new Error('Failed to fetch study sets');

    const data = await response.json();
    return (data.studySets || []).map(mapSet);
}

export async function getStudySetById(setId: string): Promise<StudySet | null> {
    const response = await fetch(`${urlBase}/sets/${setId}`, { headers: authHeaders() });
    if (!response.ok) return null;

    const data = await response.json();
    return data.studySet ? mapSet(data.studySet) : null;
}

export async function createStudySet(
    payload: Pick<StudySet, 'title' | 'description'>,
): Promise<StudySet> {
    const user = getUserData();

    const response = await fetch(`${urlBase}/sets`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({
            title: payload.title.trim(),
            description: payload.description.trim(),
            userId: user?.id,
        }),
    });

    if (!response.ok) throw new Error('Failed to create study set');

    const data = await response.json();
    return mapSet(data.studySet);
}

export async function deleteStudySet(setId: string): Promise<void> {
    const response = await fetch(`${urlBase}/sets/${setId}`, {
        method: 'DELETE',
        headers: authHeaders(),
    });

    if (!response.ok) throw new Error('Failed to delete study set');
}

// ─── Flashcards ───────────────────────────────────────────────

export async function getCardsForSet(setId: string): Promise<Flashcard[]> {
    const response = await fetch(`${urlBase}/sets/${setId}/cards`, {
        headers: authHeaders(),
    });

    if (!response.ok) throw new Error('Failed to fetch cards');

    const data = await response.json();
    return (data.flashcards || []).map(mapCard);
}

export async function createCardForSet(
    setId: string,
    payload: Pick<Flashcard, 'term' | 'definition'>,
): Promise<Flashcard> {
    const response = await fetch(`${urlBase}/sets/${setId}/cards`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({
            term: payload.term.trim(),
            definition: payload.definition.trim(),
        }),
    });

    if (!response.ok) throw new Error('Failed to create card');

    const data = await response.json();
    return mapCard(data.flashcard);
}

export async function updateCardInSet(
    cardId: string,
    payload: Pick<Flashcard, 'term' | 'definition'>,
): Promise<Flashcard | null> {
    const response = await fetch(`${urlBase}/cards/${cardId}`, {
        method: 'PUT',
        headers: authHeaders(),
        body: JSON.stringify({
            term: payload.term.trim(),
            definition: payload.definition.trim(),
        }),
    });

    if (!response.ok) return null;

    const data = await response.json();
    return mapCard(data.flashcard);
}

export async function deleteCardFromSet(cardId: string): Promise<void> {
    const response = await fetch(`${urlBase}/cards/${cardId}`, {
        method: 'DELETE',
        headers: authHeaders(),
    });

    if (!response.ok) throw new Error('Failed to delete card');
}
