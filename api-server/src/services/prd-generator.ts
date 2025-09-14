import { ChatRequest, PRDRequest, PRDResponse, DesignAsset } from '../types.js';
import { ProviderManager } from '../providers/index.js';
import { FigmaMCPConnector } from '../mcp/figma.js';

export class PRDGeneratorService {
  constructor(
    private providerManager: ProviderManager,
    private figmaConnector: FigmaMCPConnector
  ) {}

  async generatePRD(request: PRDRequest): Promise<PRDResponse> {
    let designAssets: DesignAsset[] = [];

    if (request.figmaUrl && request.includeDesignAssets) {
      try {
        designAssets = await this.figmaConnector.getDesignAssets(request.figmaUrl);
      } catch (error) {
        console.error('Failed to fetch design assets:', error);
      }
    }

    const systemPrompt = this.buildSystemPrompt(request.domain);
    const userPrompt = this.buildUserPrompt(request.description, designAssets);

    const chatRequest: ChatRequest = {
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      provider: request.provider || 'anthropic',
      temperature: 0.7,
      maxTokens: 8192,
    };

    const response = await this.providerManager.chat(chatRequest);
    const prd = this.parsePRDResponse(response);

    return {
      prd,
      designAssets: request.includeDesignAssets ? designAssets : undefined,
      metadata: {
        generatedAt: new Date().toISOString(),
        provider: request.provider || 'anthropic',
        model: request.provider === 'openai' ? 'gpt-4-turbo-preview' : 'claude-3-5-sonnet-20241022',
      }
    };
  }

  private buildSystemPrompt(domain?: string): string {
    const domainContext = domain
      ? `You are specialized in ${domain} applications. Apply domain-specific best practices and terminology.`
      : 'You are a product requirements expert.';

    return `${domainContext}

Generate comprehensive Product Requirements Documents (PRDs) that include:
1. Clear product overview
2. Detailed feature specifications
3. User stories in standard format
4. Acceptance criteria
5. Technical requirements
6. Priority levels

Format your response as valid JSON matching this structure:
{
  "title": "string",
  "overview": "string",
  "features": [
    {
      "name": "string",
      "description": "string",
      "acceptanceCriteria": ["string"],
      "priority": "high|medium|low"
    }
  ],
  "technicalRequirements": ["string"],
  "userStories": ["string"]
}`;
  }

  private buildUserPrompt(description: string, designAssets: DesignAsset[]): string {
    let prompt = `Create a PRD for: ${description}`;

    if (designAssets.length > 0) {
      prompt += '\n\nAvailable design assets from Figma:\n';

      const components = designAssets.filter(a => a.type === 'component');
      const frames = designAssets.filter(a => a.type === 'frame');
      const styles = designAssets.filter(a => a.type === 'style');

      if (components.length > 0) {
        prompt += `\nComponents (${components.length}):\n`;
        components.forEach(c => {
          prompt += `- ${c.name}${c.description ? `: ${c.description}` : ''}\n`;
        });
      }

      if (frames.length > 0) {
        prompt += `\nFrames/Screens (${frames.length}):\n`;
        frames.forEach(f => {
          prompt += `- ${f.name}${f.description ? `: ${f.description}` : ''}`;
          if (f.properties?.width && f.properties?.height) {
            prompt += ` (${f.properties.width}x${f.properties.height})`;
          }
          prompt += '\n';
        });
      }

      if (styles.length > 0) {
        prompt += `\nStyles (${styles.length}):\n`;
        styles.forEach(s => {
          prompt += `- ${s.name} (${s.properties?.styleType || 'style'})\n`;
        });
      }

      prompt += '\nIncorporate these design elements into the PRD where relevant.';
    }

    return prompt;
  }

  private parsePRDResponse(response: string): PRDResponse['prd'] {
    try {
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch (error) {
      console.error('Failed to parse PRD response:', error);
    }

    return {
      title: 'Product Requirements Document',
      overview: response.substring(0, 500),
      features: [],
      technicalRequirements: [],
      userStories: [],
    };
  }
}