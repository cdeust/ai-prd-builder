import OpenAI from 'openai';
import { BaseAIProvider } from './base.js';
import { ChatRequest } from '../types.js';

export class OpenAIProvider extends BaseAIProvider {
  private client: OpenAI;

  constructor(apiKey?: string) {
    super('openai', apiKey || process.env.OPENAI_API_KEY);
    this.validateApiKey();
    this.client = new OpenAI({ apiKey: this.apiKey });
  }

  async chat(request: ChatRequest): Promise<string> {
    const messages = request.messages.map(msg => ({
      role: msg.role,
      content: msg.content,
      ...(msg.name && { name: msg.name })
    }));

    const response = await this.client.chat.completions.create({
      model: request.model || 'gpt-4-turbo-preview',
      messages: messages as any,
      max_tokens: request.maxTokens || 4096,
      temperature: request.temperature || 0.7,
    });

    return response.choices[0]?.message?.content || '';
  }

  async *stream(request: ChatRequest): AsyncIterable<string> {
    const messages = request.messages.map(msg => ({
      role: msg.role,
      content: msg.content,
      ...(msg.name && { name: msg.name })
    }));

    const stream = await this.client.chat.completions.create({
      model: request.model || 'gpt-4-turbo-preview',
      messages: messages as any,
      max_tokens: request.maxTokens || 4096,
      temperature: request.temperature || 0.7,
      stream: true,
    });

    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content;
      if (content) {
        yield content;
      }
    }
  }
}