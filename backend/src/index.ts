import cors from 'cors';
import express, { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';
import fs from 'fs';
import path from 'path';

const app = express();
const port = process.env.PORT || 3000;

// Enable trust proxy so req.protocol works correctly behind Render/Cloud load balancers
app.enable('trust proxy');

app.use(cors());
app.use(express.json());

// --- 1. LOCAL STORAGE SETUP ---
// Define where to store audio files locally
const UPLOADS_DIR = path.join(__dirname, '../uploads');

// Ensure the directory exists when the server starts
if (!fs.existsSync(UPLOADS_DIR)) {
  console.log(`Creating uploads directory at: ${UPLOADS_DIR}`);
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Serve the 'uploads' folder publicly so the App can play the audio
// URL will be: https://your-backend.com/uploads/sessions/session_123/chunk_1.wav
app.use('/uploads', express.static(UPLOADS_DIR));


// --- 2. AUTH MIDDLEWARE ---
app.use((req: Request, res: Response, next: NextFunction) => {
  // Allow health check, uploads, and upload-chunk endpoints without auth
  // We allow /uploads so audio can be played
  // We allow /api/upload-chunk so the PUT request works
  if (req.path === '/' || 
      req.path === '/health' || 
      req.path.startsWith('/uploads') || 
      req.path.startsWith('/api/upload-chunk')) {
    return next();
  }
  
  const auth = req.header('authorization') || req.header('Authorization');
  if (!auth || !auth.toLowerCase().startsWith('bearer ')) {
    return res.status(401).json({ error: 'Unauthorized', details: 'Missing bearer token' });
  }
  next();
});

// --- 3. IN-MEMORY DATA ---
interface User { id: string; email: string; }
interface Patient { id: string; name: string; user_id: string; pronouns?: string | null; }
interface SessionItem {
  id: string; user_id: string; patient_id: string; session_title?: string | null;
  session_summary?: string | null; transcript_status?: string | null; transcript?: string | null;
  status?: string | null; date?: string | null; start_time?: string | null; end_time?: string | null;
}
interface ChunkNotificationBody {
  sessionId: string; gcsPath: string; chunkNumber: number; isLast: boolean;
  totalChunksClient: number; publicUrl: string; mimeType: string;
  selectedTemplate: string; selectedTemplateId: string; model: string;
}

const users: User[] = [{ id: 'user_123', email: 'user@example.com' }];
const patients: Patient[] = [{ id: 'patient_123', name: 'John Doe', user_id: 'user_123', pronouns: 'he/him' }];
const sessions: SessionItem[] = [];
const chunkNotifications: ChunkNotificationBody[] = [];
const templates = [
  { id: 'template_123', title: 'New Patient Visit', type: 'default' },
  { id: 'template_456', title: 'Follow-up Visit', type: 'predefined' },
];

const router = express.Router();

// --- 4. NEW UPLOAD ROUTE ---
// This handles the PUT request that the mobile app sends.
// Instead of sending to Google, the app sends to THIS server.
router.put('/upload-chunk/:sessionId/:filename', (req: Request, res: Response) => {
  const { sessionId, filename } = req.params;
  
  // Create a specific folder for this session
  const sessionDir = path.join(UPLOADS_DIR, 'sessions', sessionId);
  if (!fs.existsSync(sessionDir)) {
    fs.mkdirSync(sessionDir, { recursive: true });
  }

  const filePath = path.join(sessionDir, filename);
  const writeStream = fs.createWriteStream(filePath);

  // Pipe the request body (audio binary) directly to the file
  req.pipe(writeStream);

  writeStream.on('finish', () => {
    console.log(`Saved chunk to: ${filePath}`);
    res.status(200).json({ success: true });
  });

  writeStream.on('error', (err) => {
    console.error('Upload error:', err);
    res.status(500).json({ error: 'Upload failed' });
  });
});


// --- STANDARD API ROUTES ---

router.get('/users/asd3fd2faec', (req: Request, res: Response) => {
  const email = String(req.query.email || '').toLowerCase();
  const user = users.find((u) => u.email.toLowerCase() === email) ?? users[0];
  return res.json({ id: user.id });
});

router.get('/v1/patients', (req: Request, res: Response) => {
  const userId = String(req.query.userId || '');
  const list = patients.filter((p) => p.user_id === userId);
  return res.json({ patients: list.map((p) => ({ id: p.id, name: p.name, pronouns: p.pronouns ?? null })) });
});

router.post('/v1/add-patient-ext', (req: Request, res: Response) => {
  const { name, userId } = req.body as { name?: string; userId?: string };
  if (!name || !userId) return res.status(400).json({ error: 'Bad Request' });
  const patient: Patient = { id: `patient_${randomUUID()}`, name, user_id: userId, pronouns: null };
  patients.push(patient);
  return res.status(201).json({ patient });
});

router.get('/v1/patient-details/:patientId', (req: Request, res: Response) => {
  const { patientId } = req.params;
  const p = patients.find((x) => x.id === patientId);
  if (!p) return res.status(404).json({ error: 'Not Found' });
  return res.json({
    id: p.id, name: p.name, pronouns: p.pronouns ?? 'he/him', email: 'john@example.com',
    background: 'Patient background information', medical_history: 'Previous medical conditions',
    family_history: 'Family medical history', social_history: 'Social history information',
    previous_treatment: 'Previous treatments',
  });
});

router.get('/v1/fetch-session-by-patient/:patientId', (req: Request, res: Response) => {
  const { patientId } = req.params;
  const list = sessions.filter((s) => s.patient_id === patientId);
  // Dynamic Base URL for audio
  const baseUrl = `${req.protocol}://${req.get('host')}`;

  return res.json({
    sessions: list.map((s) => ({
      id: s.id,
      date: s.date ?? new Date().toISOString().slice(0, 10),
      session_title: s.session_title ?? 'Consultation',
      session_summary: s.session_summary ?? 'Patient consultation summary',
      start_time: s.start_time ?? new Date().toISOString(),
      // Point to local file
      audio_url: `${baseUrl}/uploads/sessions/${s.id}/chunk_1.wav`,
    })),
  });
});

router.get('/v1/all-session', (req: Request, res: Response) => {
  const userId = String(req.query.userId || '');
  const list = sessions.filter((s) => s.user_id === userId);
  const patientMap: Record<string, { name: string; pronouns: string | null }> = {};
  patients.forEach((p) => { patientMap[p.id] = { name: p.name, pronouns: p.pronouns ?? 'he/him' }; });

  const baseUrl = `${req.protocol}://${req.get('host')}`;

  return res.json({
    sessions: list.map((s) => {
      const sessionChunks = chunkNotifications.filter((c) => c.sessionId === s.id);
      
      // If we have chunks, point to the first one as a demo
      // In a real app, you would merge these files.
      const audioUrl = sessionChunks.length > 0 
        ? sessionChunks[0].publicUrl 
        : `${baseUrl}/uploads/sessions/${s.id}/chunk_1.wav`;
      
      return {
        id: s.id, user_id: s.user_id, patient_id: s.patient_id,
        session_title: s.session_title ?? 'Initial Consultation',
        session_summary: s.session_summary ?? 'Patient consultation summary',
        transcript_status: s.transcript_status ?? 'completed',
        transcript: s.transcript ?? 'Full transcript text...',
        status: s.status ?? 'completed',
        date: s.date ?? new Date().toISOString().slice(0, 10),
        start_time: s.start_time ?? new Date().toISOString(),
        end_time: s.end_time ?? new Date().toISOString(),
        patient_name: patients.find((p) => p.id === s.patient_id)?.name ?? 'Unknown',
        pronouns: patients.find((p) => p.id === s.patient_id)?.pronouns ?? 'he/him',
        email: 'john@example.com', background: 'Patient background', duration: '30 minutes',
        medical_history: 'Previous conditions', family_history: 'Family history',
        social_history: 'Social history', previous_treatment: 'Previous treatments',
        patient_pronouns: patients.find((p) => p.id === s.patient_id)?.pronouns ?? 'he/him',
        clinical_notes: [] as any[],
        audio_url: audioUrl,
      };
    }),
    patientMap,
  });
});

router.get('/v1/fetch-default-template-ext', (req: Request, res: Response) => {
  return res.json({ success: true, data: templates });
});

router.post('/v1/upload-session', (req: Request, res: Response) => {
  const { patientId, userId, patientName, status, startTime, templateId } = req.body as any;
  if (!patientId || !userId || !patientName || !status || !startTime || !templateId) {
    return res.status(400).json({ error: 'Bad Request' });
  }
  const id = `session_${randomUUID()}`;
  const session: SessionItem = {
    id, user_id: userId, patient_id: patientId, session_title: 'Initial Consultation',
    session_summary: '', transcript_status: 'pending', transcript: '', status,
    date: startTime.slice(0, 10), start_time: startTime, end_time: null,
  };
  sessions.push(session);
  return res.status(201).json({ id });
});

// --- 5. UPDATED PRESIGNED URL LOGIC ---
router.post('/v1/get-presigned-url', (req: Request, res: Response) => {
  const { sessionId, chunkNumber, mimeType } = req.body as { sessionId: string; chunkNumber: number; mimeType: string; };

  if (!sessionId || typeof chunkNumber !== 'number' || !mimeType) {
    return res.status(400).json({ error: 'Bad Request' });
  }

  const filename = `chunk_${chunkNumber}.wav`;
  const baseUrl = `${req.protocol}://${req.get('host')}`;
  
  // INSTEAD of Google Cloud, we tell the app to upload to OUR server
  const url = `${baseUrl}/api/upload-chunk/${sessionId}/${filename}`;
  
  // The Public URL is how the app will PLAY the audio later
  const publicUrl = `${baseUrl}/uploads/sessions/${sessionId}/${filename}`;
  const gcsPath = `sessions/${sessionId}/${filename}`; // Just for reference

  return res.json({ url, gcsPath, publicUrl });
});

router.post('/v1/notify-chunk-uploaded', (req: Request, res: Response) => {
  const body = req.body as ChunkNotificationBody;
  if (!body.sessionId || !body.gcsPath || typeof body.chunkNumber !== 'number') {
    return res.status(400).json({ error: 'Bad Request' });
  }
  chunkNotifications.push(body);
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

app.get('/', (_req: Request, res: Response) => {
  res.json({ status: 'running', message: 'Medical Copilot Backend API', version: '1.0.0' });
});

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`medical_copilot backend listening on port ${port}`);
});