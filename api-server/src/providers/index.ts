import { AIProvider, ChatRequest } from '../types.js';
import { AnthropicProvider } from './anthropic.js';
import { OpenAIProvider } from './openai.js';

export class ProviderManager {
  private providers: Map<string, AIProvider> = new Map();

  constructor() {
    this.registerDefaultProviders();
  }

  private registerDefaultProviders(): void {
    if (process.env.ANTHROPIC_API_KEY) {
      this.registerProvider(new AnthropicProvider());
    }
    if (process.env.OPENAI_API_KEY) {
      this.registerProvider(new OpenAIProvider());
    }
  }

  registerProvider(provider: AIProvider): void {
    this.providers.set(provider.name, provider);
  }

  getProvider(name: string): AIProvider {
    const provider = this.providers.get(name);
    if (!provider) {
      throw new Error(`Provider ${name} not found. Available: ${Array.from(this.providers.keys()).join(', ')}`);
    }
    return provider;
  }

  async chat(request: ChatRequest): Promise<string> {
    const provider = this.getProvider(request.provider || 'anthropic');
    return provider.chat(request);
  }

  async *stream(request: ChatRequest): AsyncIterable<string> {
    const provider = this.getProvider(request.provider || 'anthropic');
    if (!provider.stream) {
      throw new Error(`Provider ${provider.name} does not support streaming`);
    }
    yield* provider.stream(request);
  }

  listProviders(): string[] {
    return Array.from(this.providers.keys());
  }
}

export { AnthropicProvider, OpenAIProvider };