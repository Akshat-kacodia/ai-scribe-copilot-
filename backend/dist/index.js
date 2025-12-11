"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cors_1 = __importDefault(require("cors"));
const express_1 = __importDefault(require("express"));
const crypto_1 = require("crypto");
const app = (0, express_1.default)();
const port = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// --- Simple auth middleware matching "Bearer <token>" pattern ---
// In mock mode, accepts any Bearer token. For production, validate tokens properly.
app.use((req, res, next) => {
    // Allow health check endpoint without auth
    if (req.path === '/' || req.path === '/health') {
        return next();
    }
    const auth = req.header('authorization') || req.header('Authorization');
    if (!auth || !auth.toLowerCase().startsWith('bearer ')) {
        return res.status(401).json({ error: 'Unauthorized', details: 'Missing bearer token' });
    }
    // In production, validate token here:
    // const token = auth.replace('Bearer ', '');
    // if (!isValidToken(token)) {
    //   return res.status(401).json({ error: 'Unauthorized', details: 'Invalid token' });
    // }
    next();
});
const users = [
    { id: 'user_123', email: 'user@example.com' },
];
const patients = [
    {
        id: 'patient_123',
        name: 'John Doe',
        user_id: 'user_123',
        pronouns: 'he/him',
    },
];
const sessions = [];
const chunkNotifications = [];
const templates = [
    { id: 'template_123', title: 'New Patient Visit', type: 'default' },
    { id: 'template_456', title: 'Follow-up Visit', type: 'predefined' },
];
// Prefix all routes with /api to match Flutter baseUrl.
const router = express_1.default.Router();
// GET /users/asd3fd2faec?email=...
router.get('/users/asd3fd2faec', (req, res) => {
    var _a;
    const email = String(req.query.email || '').toLowerCase();
    const user = (_a = users.find((u) => u.email.toLowerCase() === email)) !== null && _a !== void 0 ? _a : users[0];
    return res.json({ id: user.id });
});
// GET /v1/patients?userId=...
router.get('/v1/patients', (req, res) => {
    const userId = String(req.query.userId || '');
    const list = patients.filter((p) => p.user_id === userId);
    return res.json({
        patients: list.map((p) => {
            var _a;
            return ({
                id: p.id,
                name: p.name,
                pronouns: (_a = p.pronouns) !== null && _a !== void 0 ? _a : null,
            });
        }),
    });
});
// POST /v1/add-patient-ext
router.post('/v1/add-patient-ext', (req, res) => {
    const { name, userId } = req.body;
    if (!name || !userId) {
        return res.status(400).json({ error: 'Bad Request', details: 'name and userId are required' });
    }
    const patient = {
        id: `patient_${(0, crypto_1.randomUUID)()}`,
        name,
        user_id: userId,
        pronouns: null,
    };
    patients.push(patient);
    return res.status(201).json({
        patient,
    });
});
// GET /v1/patient-details/:patientId
router.get('/v1/patient-details/:patientId', (req, res) => {
    var _a;
    const { patientId } = req.params;
    const p = patients.find((x) => x.id === patientId);
    if (!p) {
        return res.status(404).json({ error: 'Not Found', details: 'Patient not found' });
    }
    return res.json({
        id: p.id,
        name: p.name,
        pronouns: (_a = p.pronouns) !== null && _a !== void 0 ? _a : 'he/him',
        email: 'john@example.com',
        background: 'Patient background information',
        medical_history: 'Previous medical conditions',
        family_history: 'Family medical history',
        social_history: 'Social history information',
        previous_treatment: 'Previous treatments',
    });
});
// GET /v1/fetch-session-by-patient/:patientId
router.get('/v1/fetch-session-by-patient/:patientId', (req, res) => {
    const { patientId } = req.params;
    const list = sessions.filter((s) => s.patient_id === patientId);
    return res.json({
        sessions: list.map((s) => {
            var _a, _b, _c, _d;
            return ({
                id: s.id,
                date: (_a = s.date) !== null && _a !== void 0 ? _a : new Date().toISOString().slice(0, 10),
                session_title: (_b = s.session_title) !== null && _b !== void 0 ? _b : 'Consultation',
                session_summary: (_c = s.session_summary) !== null && _c !== void 0 ? _c : 'Patient consultation summary',
                start_time: (_d = s.start_time) !== null && _d !== void 0 ? _d : new Date().toISOString(),
                audio_url: `https://storage.googleapis.com/demo-bucket/sessions/${s.id}/audio.wav`,
            });
        }),
    });
});
// GET /v1/all-session?userId=...
router.get('/v1/all-session', (req, res) => {
    const userId = String(req.query.userId || '');
    const list = sessions.filter((s) => s.user_id === userId);
    const patientMap = {};
    patients.forEach((p) => {
        var _a;
        patientMap[p.id] = { name: p.name, pronouns: (_a = p.pronouns) !== null && _a !== void 0 ? _a : 'he/him' };
    });
    return res.json({
        sessions: list.map((s) => {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p;
            // Generate audio URL from session chunks or use a mock URL
            const sessionChunks = chunkNotifications.filter((c) => c.sessionId === s.id);
            const audioUrl = sessionChunks.length > 0
                ? sessionChunks[0].publicUrl // Use first chunk's public URL as mock combined audio
                : `https://storage.googleapis.com/demo-bucket/sessions/${s.id}/audio.wav`;
            return {
                id: s.id,
                user_id: s.user_id,
                patient_id: s.patient_id,
                session_title: (_a = s.session_title) !== null && _a !== void 0 ? _a : 'Initial Consultation',
                session_summary: (_b = s.session_summary) !== null && _b !== void 0 ? _b : 'Patient consultation summary',
                transcript_status: (_c = s.transcript_status) !== null && _c !== void 0 ? _c : 'completed',
                transcript: (_d = s.transcript) !== null && _d !== void 0 ? _d : 'Full transcript text...',
                status: (_e = s.status) !== null && _e !== void 0 ? _e : 'completed',
                date: (_f = s.date) !== null && _f !== void 0 ? _f : new Date().toISOString().slice(0, 10),
                start_time: (_g = s.start_time) !== null && _g !== void 0 ? _g : new Date().toISOString(),
                end_time: (_h = s.end_time) !== null && _h !== void 0 ? _h : new Date().toISOString(),
                patient_name: (_k = (_j = patients.find((p) => p.id === s.patient_id)) === null || _j === void 0 ? void 0 : _j.name) !== null && _k !== void 0 ? _k : 'Unknown',
                pronouns: (_m = (_l = patients.find((p) => p.id === s.patient_id)) === null || _l === void 0 ? void 0 : _l.pronouns) !== null && _m !== void 0 ? _m : 'he/him',
                email: 'john@example.com',
                background: 'Patient background',
                duration: '30 minutes',
                medical_history: 'Previous conditions',
                family_history: 'Family history',
                social_history: 'Social history',
                previous_treatment: 'Previous treatments',
                patient_pronouns: (_p = (_o = patients.find((p) => p.id === s.patient_id)) === null || _o === void 0 ? void 0 : _o.pronouns) !== null && _p !== void 0 ? _p : 'he/him',
                clinical_notes: [],
                audio_url: audioUrl,
            };
        }),
        patientMap,
    });
});
// GET /v1/fetch-default-template-ext?userId=...
router.get('/v1/fetch-default-template-ext', (req, res) => {
    // userId is accepted but not used for filtering in this mock.
    return res.json({ success: true, data: templates });
});
// POST /v1/upload-session
router.post('/v1/upload-session', (req, res) => {
    const { patientId, userId, patientName, status, startTime, templateId } = req.body;
    if (!patientId || !userId || !patientName || !status || !startTime || !templateId) {
        return res.status(400).json({ error: 'Bad Request', details: 'Missing required fields' });
    }
    const id = `session_${(0, crypto_1.randomUUID)()}`;
    const session = {
        id,
        user_id: userId,
        patient_id: patientId,
        session_title: 'Initial Consultation',
        session_summary: '',
        transcript_status: 'pending',
        transcript: '',
        status,
        date: startTime.slice(0, 10),
        start_time: startTime,
        end_time: null,
    };
    sessions.push(session);
    return res.status(201).json({ id });
});
// POST /v1/get-presigned-url
router.post('/v1/get-presigned-url', (req, res) => {
    const { sessionId, chunkNumber, mimeType } = req.body;
    if (!sessionId || typeof chunkNumber !== 'number' || !mimeType) {
        return res.status(400).json({ error: 'Bad Request', details: 'Invalid presigned URL request' });
    }
    const gcsPath = `sessions/${sessionId}/chunk_${chunkNumber}.wav`;
    const url = `https://storage.googleapis.com/demo-bucket/${gcsPath}`;
    const publicUrl = url;
    return res.json({ url, gcsPath, publicUrl });
});
// POST /v1/notify-chunk-uploaded
router.post('/v1/notify-chunk-uploaded', (req, res) => {
    const body = req.body;
    if (!body.sessionId || !body.gcsPath || typeof body.chunkNumber !== 'number') {
        return res.status(400).json({ error: 'Bad Request', details: 'Invalid chunk notification' });
    }
    chunkNotifications.push(body);
    // When last chunk is received, mark session as completed.
    if (body.isLast) {
        const s = sessions.find((x) => x.id === body.sessionId);
        if (s) {
            s.status = 'completed';
            s.transcript_status = 'completed';
            s.transcript = 'Full transcript text...';
            s.end_time = new Date().toISOString();
        }
    }
    return res.json({});
});
app.use('/api', router);
app.get('/', (_req, res) => {
    res.json({
        status: 'running',
        message: 'Medical Copilot Backend API',
        version: '1.0.0',
        endpoints: {
            base: '/api',
            health: '/health',
        },
    });
});
app.get('/health', (_req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});
app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`medical_copilot backend listening on port ${port}`);
});
