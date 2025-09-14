import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { ChatRequestSchema, PRDRequestSchema } from './types.js';
import { ProviderManager } from './providers/index.js';
import { FigmaMCPConnector } from './mcp/figma.js';
import { PRDGeneratorService } from './services/prd-generator.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
}));
app.use(express.json());

const providerManager = new ProviderManager();
const figmaConnector = new FigmaMCPConnector();
const prdGenerator = new PRDGeneratorService(providerManager, figmaConnector);

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    providers: providerManager.listProviders(),
    mcp: {
      enabled: process.env.MCP_ENABLED === 'true',
      figma: !!process.env.FIGMA_PERSONAL_ACCESS_TOKEN,
    }
  });
});

app.post('/chat', async (req, res) => {
  try {
    const request = ChatRequestSchema.parse(req.body);

    if (request.stream) {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });

      for await (const chunk of providerManager.stream(request)) {
        res.write(`data: ${JSON.stringify({ content: chunk })}\n\n`);
      }

      res.write('data: [DONE]\n\n');
      res.end();
    } else {
      const response = await providerManager.chat(request);
      res.json({ content: response });
    }
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({
      error: error instanceof Error ? error.message : 'Internal server error'
    });
  }
});

app.post('/prd/generate', async (req, res) => {
  try {
    const request = PRDRequestSchema.parse(req.body);
    const response = await prdGenerator.generatePRD(request);
    res.json(response);
  } catch (error) {
    console.error('PRD generation error:', error);
    res.status(500).json({
      error: error instanceof Error ? error.message : 'Internal server error'
    });
  }
});

app.get('/providers', (req, res) => {
  res.json({
    providers: providerManager.listProviders(),
    models: {
      anthropic: ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229'],
      openai: ['gpt-4-turbo-preview', 'gpt-4', 'gpt-3.5-turbo'],
    }
  });
});

const server = app.listen(port, () => {
  console.log(`AI Provider API running on http://localhost:${port}`);
  console.log(`Available providers: ${providerManager.listProviders().join(', ')}`);
  console.log(`MCP enabled: ${process.env.MCP_ENABLED === 'true'}`);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await figmaConnector.disconnect();
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});