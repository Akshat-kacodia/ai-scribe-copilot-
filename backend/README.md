# Medical Copilot Backend

A mock backend API server for the Medical Copilot Flutter application. This backend implements all the endpoints specified in the API documentation.

## Quick Start

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run in development mode:**
   ```bash
   npm run dev
   ```

   The server will start on `http://localhost:3000`

3. **Build for production:**
   ```bash
   npm run build
   npm start
   ```

## Docker Deployment

### Using Docker Compose

```bash
docker-compose up --build
```

This will build and start the backend container on port 3000.

### Using Docker directly

```bash
# Build the image
docker build -t medical-copilot-backend .

# Run the container
docker run -p 3000:3000 -e PORT=3000 medical-copilot-backend
```

## Cloud Deployment

### Google Cloud Run

1. **Build and push the container:**
   ```bash
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/medical-copilot-backend
   ```

2. **Deploy to Cloud Run:**
   ```bash
   gcloud run deploy medical-copilot-backend \
     --image gcr.io/YOUR_PROJECT_ID/medical-copilot-backend \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --port 3000
   ```

3. **Get the deployed URL:**
   ```bash
   gcloud run services describe medical-copilot-backend --region us-central1 --format 'value(status.url)'
   ```

### Other Platforms

- **Heroku**: Use the included `Dockerfile` or deploy as Node.js app
- **AWS ECS/Fargate**: Use Docker image
- **Azure Container Instances**: Use Docker image
- **Railway/Render**: Connect GitHub repo, auto-deploys

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)

## API Endpoints

All endpoints require Bearer token authentication (any token is accepted in mock mode).

### Base URL
- Local: `http://localhost:3000/api`
- Deployed: `https://your-deployed-url.com/api`

### Endpoints

- `GET /api/users/asd3fd2faec?email={email}` - Get user ID by email
- `GET /api/v1/patients?userId={userId}` - Get patients for user
- `POST /api/v1/add-patient-ext` - Create new patient
- `GET /api/v1/patient-details/{patientId}` - Get patient details
- `GET /api/v1/fetch-session-by-patient/{patientId}` - Get sessions for patient
- `GET /api/v1/all-session?userId={userId}` - Get all sessions for user
- `GET /api/v1/fetch-default-template-ext?userId={userId}` - Get templates
- `POST /api/v1/upload-session` - Create recording session
- `POST /api/v1/get-presigned-url` - Get presigned URL for chunk upload
- `POST /api/v1/notify-chunk-uploaded` - Notify chunk uploaded

## Authentication

The mock backend accepts any Bearer token. In production, implement proper authentication:

```typescript
// Example: Validate token
const validTokens = ['your-secret-token-1', 'your-secret-token-2'];
const token = auth.replace('Bearer ', '');
if (!validTokens.includes(token)) {
  return res.status(401).json({ error: 'Invalid token' });
}
```

## Data Storage

Currently uses in-memory storage (data resets on restart). For production:

1. **Add a database:**
   - PostgreSQL/MySQL for relational data
   - MongoDB for document storage
   - SQLite for simple deployments

2. **Add file storage:**
   - Google Cloud Storage for presigned URLs
   - AWS S3 for presigned URLs
   - Local filesystem (not recommended for production)

## Frontend Configuration

After deploying, update the Flutter app:

1. Open Settings in the app
2. Set "API Base URL" to your deployed backend URL (e.g., `https://your-backend.run.app/api`)
3. Set "Backend Base URL" to the same URL
4. Set "Auth Token" to any value (mock backend accepts any token)

## Testing

Test the backend with curl:

```bash
# Health check
curl http://localhost:3000/

# Get user ID (requires Bearer token)
curl -H "Authorization: Bearer test-token" \
  "http://localhost:3000/api/users/asd3fd2faec?email=user@example.com"

# Get patients (requires Bearer token)
curl -H "Authorization: Bearer test-token" \
  "http://localhost:3000/api/v1/patients?userId=user_123"
```

## Notes

- This is a **mock backend** for development/testing
- Data is stored in-memory and resets on restart
- Presigned URLs are mock URLs (not real GCS/S3 URLs)
- For production, implement proper database, authentication, and file storage

