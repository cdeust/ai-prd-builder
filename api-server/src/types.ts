import { z } from 'zod';

export const ChatMessageSchema = z.object({
  role: z.enum(['system', 'user', 'assistant']),
  content: z.string(),
  name: z.string().optional(),
});

export type ChatMessage = z.infer<typeof ChatMessageSchema>;

export const ChatRequestSchema = z.object({
  messages: z.array(ChatMessageSchema),
  provider: z.enum(['anthropic', 'openai', 'local']).optional().default('anthropic'),
  model: z.string().optional(),
  temperature: z.number().min(0).max(2).optional().default(0.7),
  maxTokens: z.number().positive().optional().default(4096),
  stream: z.boolean().optional().default(false),
});

export type ChatRequest = z.infer<typeof ChatRequestSchema>;

export const PRDRequestSchema = z.object({
  description: z.string(),
  figmaUrl: z.string().url().optional(),
  domain: z.string().optional(),
  includeDesignAssets: z.boolean().optional().default(false),
  provider: z.enum(['anthropic', 'openai']).optional().default('anthropic'),
});

export type PRDRequest = z.infer<typeof PRDRequestSchema>;

export interface DesignAsset {
  type: 'component' | 'frame' | 'style';
  name: string;
  description?: string;
  properties?: Record<string, any>;
  thumbnail?: string;
}

export interface PRDResponse {
  prd: {
    title: string;
    overview: string;
    features: Array<{
      name: string;
      description: string;
      acceptanceCriteria: string[];
      priority: 'high' | 'medium' | 'low';
    }>;
    technicalRequirements: string[];
    userStories: string[];
  };
  designAssets?: DesignAsset[];
  metadata?: {
    generatedAt: string;
    provider: string;
    model: string;
  };
}

export interface AIProvider {
  name: string;
  chat(request: ChatRequest): Promise<string>;
  stream?(request: ChatRequest): AsyncIterable<string>;
}