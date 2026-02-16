import routes from './routes/index.routes.js';
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "20mb" }));
app.use(morgan('dev'));

app.get('/', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Backend is running',
    data: {
      health: '/api/health',
    },
  });
});

app.use('/api', routes);

export default app;
