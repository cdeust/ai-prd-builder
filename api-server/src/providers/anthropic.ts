import Anthropic from '@anthropic-ai/sdk';
import { BaseAIProvider } from './base.js';
import { ChatRequest } from '../types.js';

export class AnthropicProvider extends BaseAIProvider {
  private client: Anthropic;

  constructor(apiKey?: string) {
    super('anthropic', apiKey || process.env.ANTHROPIC_API_KEY);
    this.validateApiKey();
    this.client = new Anthropic({ apiKey: this.apiKey });
  }

  async chat(request: ChatRequest): Promise<string> {
    const messages = request.messages.map(msg => ({
      role: msg.role === 'system' ? 'user' as const : msg.role as 'user' | 'assistant',
      content: msg.role === 'system'
        ? `System: ${msg.content}`
        : msg.content
    }));

    const response = await this.client.messages.create({
      model: request.model || 'claude-3-5-sonnet-20241022',
      messages,
      max_tokens: request.maxTokens || 4096,
      temperature: request.temperature || 0.7,
    });

    return response.content
      .filter(block => block.type === 'text')
      .map(block => block.type === 'text' ? block.text : '')
      .join('\n');
  }

  async *stream(request: ChatRequest): AsyncIterable<string> {
    const messages = request.messages.map(msg => ({
      role: msg.role === 'system' ? 'user' as const : msg.role as 'user' | 'assistant',
      content: msg.role === 'system'
        ? `System: ${msg.content}`
        : msg.content
    }));

    const stream = await this.client.messages.create({
      model: request.model || 'claude-3-5-sonnet-20241022',
      messages,
      max_tokens: request.maxTokens || 4096,
      temperature: request.temperature || 0.7,
      stream: true,
    });

    for await (const chunk of stream) {
      if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
        yield chunk.delta.text;
      }
    }
  }
}