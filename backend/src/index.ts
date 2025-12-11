import cors from 'cors';
import express, { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// --- Simple auth middleware matching "Bearer <token>" pattern ---
// In mock mode, accepts any Bearer token. For production, validate tokens properly.
app.use((req: Request, res: Response, next: NextFunction) => {
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

// In-memory data stores for demo purposes only.
interface User {
  id: string;
  email: string;
}

interface Patient {
  id: string;
  name: string;
  user_id: string;
  pronouns?: string | null;
}

interface SessionItem {
  id: string;
  user_id: string;
  patient_id: string;
  session_title?: string | null;
  session_summary?: string | null;
  transcript_status?: string | null;
  transcript?: string | null;
  status?: string | null;
  date?: string | null;
  start_time?: string | null;
  end_time?: string | null;
}

interface ChunkNotificationBody {
  sessionId: string;
  gcsPath: string;
  chunkNumber: number;
  isLast: boolean;
  totalChunksClient: number;
  publicUrl: string;
  mimeType: string;
  selectedTemplate: string;
  selectedTemplateId: string;
  model: string;
}

const users: User[] = [
  { id: 'user_123', email: 'user@example.com' },
];

const patients: Patient[] = [
  {
    id: 'patient_123',
    name: 'John Doe',
    user_id: 'user_123',
    pronouns: 'he/him',
  },
];

const sessions: SessionItem[] = [];
const chunkNotifications: ChunkNotificationBody[] = [];

const templates = [
  { id: 'template_123', title: 'New Patient Visit', type: 'default' },
  { id: 'template_456', title: 'Follow-up Visit', type: 'predefined' },
];

// Prefix all routes with /api to match Flutter baseUrl.
const router = express.Router();

// GET /users/asd3fd2faec?email=...
router.get('/users/asd3fd2faec', (req: Request, res: Response) => {
  const email = String(req.query.email || '').toLowerCase();
  const user = users.find((u) => u.email.toLowerCase() === email) ?? users[0];
  return res.json({ id: user.id });
});

// GET /v1/patients?userId=...
router.get('/v1/patients', (req: Request, res: Response) => {
  const userId = String(req.query.userId || '');
  const list = patients.filter((p) => p.user_id === userId);
  return res.json({
    patients: list.map((p) => ({ 
      id: p.id, 
      name: p.name,
      pronouns: p.pronouns ?? null,
    })),
  });
});

// POST /v1/add-patient-ext
router.post('/v1/add-patient-ext', (req: Request, res: Response) => {
  const { name, userId } = req.body as { name?: string; userId?: string };
  if (!name || !userId) {
    return res.status(400).json({ error: 'Bad Request', details: 'name and userId are required' });
  }
  const patient: Patient = {
    id: `patient_${randomUUID()}`,
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
router.get('/v1/patient-details/:patientId', (req: Request, res: Response) => {
  const { patientId } = req.params;
  const p = patients.find((x) => x.id === patientId);
  if (!p) {
    return res.status(404).json({ error: 'Not Found', details: 'Patient not found' });
  }
  return res.json({
    id: p.id,
    name: p.name,
    pronouns: p.pronouns ?? 'he/him',
    email: 'john@example.com',
    background: 'Patient background information',
    medical_history: 'Previous medical conditions',
    family_history: 'Family medical history',
    social_history: 'Social history information',
    previous_treatment: 'Previous treatments',
  });
});

// GET /v1/fetch-session-by-patient/:patientId
router.get('/v1/fetch-session-by-patient/:patientId', (req: Request, res: Response) => {
  const { patientId } = req.params;
  const list = sessions.filter((s) => s.patient_id === patientId);
  return res.json({
    sessions: list.map((s) => ({
      id: s.id,
      date: s.date ?? new Date().toISOString().slice(0, 10),
      session_title: s.session_title ?? 'Consultation',
      session_summary: s.session_summary ?? 'Patient consultation summary',
      start_time: s.start_time ?? new Date().toISOString(),
      audio_url: `https://storage.googleapis.com/demo-bucket/sessions/${s.id}/audio.wav`,
    })),
  });
});

// GET /v1/all-session?userId=...
router.get('/v1/all-session', (req: Request, res: Response) => {
  const userId = String(req.query.userId || '');
  const list = sessions.filter((s) => s.user_id === userId);

  const patientMap: Record<string, { name: string; pronouns: string | null }> = {};
  patients.forEach((p) => {
    patientMap[p.id] = { name: p.name, pronouns: p.pronouns ?? 'he/him' };
  });

  return res.json({
    sessions: list.map((s) => {
      // Generate audio URL from session chunks or use a mock URL
      const sessionChunks = chunkNotifications.filter((c) => c.sessionId === s.id);
      const audioUrl = sessionChunks.length > 0 
        ? sessionChunks[0].publicUrl // Use first chunk's public URL as mock combined audio
        : `https://storage.googleapis.com/demo-bucket/sessions/${s.id}/audio.wav`;
      
      return {
        id: s.id,
        user_id: s.user_id,
        patient_id: s.patient_id,
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
        email: 'john@example.com',
        background: 'Patient background',
        duration: '30 minutes',
        medical_history: 'Previous conditions',
        family_history: 'Family history',
        social_history: 'Social history',
        previous_treatment: 'Previous treatments',
        patient_pronouns: patients.find((p) => p.id === s.patient_id)?.pronouns ?? 'he/him',
        clinical_notes: [] as any[],
        audio_url: audioUrl,
      };
    }),
    patientMap,
  });
});

// GET /v1/fetch-default-template-ext?userId=...
router.get('/v1/fetch-default-template-ext', (req: Request, res: Response) => {
  // userId is accepted but not used for filtering in this mock.
  return res.json({ success: true, data: templates });
});

// POST /v1/upload-session
router.post('/v1/upload-session', (req: Request, res: Response) => {
  const { patientId, userId, patientName, status, startTime, templateId } = req.body as {
    patientId: string;
    userId: string;
    patientName: string;
    status: string;
    startTime: string;
    templateId: string;
  };

  if (!patientId || !userId || !patientName || !status || !startTime || !templateId) {
    return res.status(400).json({ error: 'Bad Request', details: 'Missing required fields' });
  }

  const id = `session_${randomUUID()}`;
  const session: SessionItem = {
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
router.post('/v1/get-presigned-url', (req: Request, res: Response) => {
  const { sessionId, chunkNumber, mimeType } = req.body as {
    sessionId: string;
    chunkNumber: number;
    mimeType: string;
  };

  if (!sessionId || typeof chunkNumber !== 'number' || !mimeType) {
    return res.status(400).json({ error: 'Bad Request', details: 'Invalid presigned URL request' });
  }

  const gcsPath = `sessions/${sessionId}/chunk_${chunkNumber}.wav`;
  const url = `https://storage.googleapis.com/demo-bucket/${gcsPath}`;
  const publicUrl = url;

  return res.json({ url, gcsPath, publicUrl });
});

// POST /v1/notify-chunk-uploaded
router.post('/v1/notify-chunk-uploaded', (req: Request, res: Response) => {
  const body = req.body as ChunkNotificationBody;
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

app.get('/', (_req: Request, res: Response) => {
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

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`medical_copilot backend listening on port ${port}`);
});
