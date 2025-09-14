import { AIProvider, ChatRequest } from '../types.js';

export abstract class BaseAIProvider implements AIProvider {
  constructor(
    public readonly name: string,
    protected readonly apiKey?: string
  ) {}

  abstract chat(request: ChatRequest): Promise<string>;

  async *stream(request: ChatRequest): AsyncIterable<string> {
    const response = await this.chat(request);
    yield response;
  }

  protected validateApiKey(): void {
    if (!this.apiKey) {
      throw new Error(`API key not configured for ${this.name} provider`);
    }
  }
}