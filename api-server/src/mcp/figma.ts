import { MCPClient } from './client.js';
import { DesignAsset } from '../types.js';

export class FigmaMCPConnector {
  private client: MCPClient;
  private isConnected: boolean = false;

  constructor() {
    const serverPath = process.env.MCP_FIGMA_SERVER_PATH || 'npx';
    const serverArgs = serverPath === 'npx'
      ? ['-y', '@figma/mcp-server-figma']
      : [];

    this.client = new MCPClient(serverPath, serverArgs);
  }

  async connect(): Promise<void> {
    if (this.isConnected) return;

    try {
      await this.client.connect();
      this.isConnected = true;
      console.log('Connected to Figma MCP server');
    } catch (error) {
      console.error('Failed to connect to Figma MCP server:', error);
      throw new Error('Figma MCP connection failed');
    }
  }

  async disconnect(): Promise<void> {
    if (!this.isConnected) return;
    await this.client.disconnect();
    this.isConnected = false;
  }

  async getDesignAssets(figmaUrl: string): Promise<DesignAsset[]> {
    await this.connect();

    try {
      const fileKey = this.extractFileKey(figmaUrl);
      if (!fileKey) {
        throw new Error('Invalid Figma URL');
      }

      const tools = await this.client.listTools();
      const getFileTool = tools.find(t => t.name === 'get_file');

      if (!getFileTool) {
        throw new Error('Figma get_file tool not available');
      }

      const fileData = await this.client.callTool('get_file', {
        file_key: fileKey,
      });

      return this.parseDesignAssets(fileData);
    } catch (error) {
      console.error('Error fetching Figma design assets:', error);
      throw error;
    }
  }

  async getComponents(figmaUrl: string): Promise<DesignAsset[]> {
    await this.connect();

    try {
      const fileKey = this.extractFileKey(figmaUrl);
      if (!fileKey) {
        throw new Error('Invalid Figma URL');
      }

      const components = await this.client.callTool('get_components', {
        file_key: fileKey,
      });

      return this.parseComponents(components);
    } catch (error) {
      console.error('Error fetching Figma components:', error);
      return [];
    }
  }

  async getStyles(figmaUrl: string): Promise<DesignAsset[]> {
    await this.connect();

    try {
      const fileKey = this.extractFileKey(figmaUrl);
      if (!fileKey) {
        throw new Error('Invalid Figma URL');
      }

      const styles = await this.client.callTool('get_styles', {
        file_key: fileKey,
      });

      return this.parseStyles(styles);
    } catch (error) {
      console.error('Error fetching Figma styles:', error);
      return [];
    }
  }

  private extractFileKey(figmaUrl: string): string | null {
    const match = figmaUrl.match(/figma\.com\/file\/([a-zA-Z0-9]+)/);
    return match ? match[1] : null;
  }

  private parseDesignAssets(fileData: any): DesignAsset[] {
    const assets: DesignAsset[] = [];

    if (!fileData || !fileData.document) {
      return assets;
    }

    const parseNode = (node: any, type: 'frame' | 'component' = 'frame'): void => {
      if (node.type === 'COMPONENT' || node.type === 'COMPONENT_SET') {
        assets.push({
          type: 'component',
          name: node.name,
          description: node.description,
          properties: {
            id: node.id,
            type: node.type,
          },
        });
      } else if (node.type === 'FRAME' && type === 'frame') {
        assets.push({
          type: 'frame',
          name: node.name,
          description: node.description,
          properties: {
            id: node.id,
            width: node.absoluteBoundingBox?.width,
            height: node.absoluteBoundingBox?.height,
          },
        });
      }

      if (node.children) {
        node.children.forEach((child: any) => parseNode(child, type));
      }
    };

    parseNode(fileData.document);
    return assets;
  }

  private parseComponents(components: any): DesignAsset[] {
    if (!components || !components.meta?.components) {
      return [];
    }

    return Object.entries(components.meta.components).map(([id, comp]: [string, any]) => ({
      type: 'component',
      name: comp.name,
      description: comp.description,
      properties: {
        id,
        key: comp.key,
        containingFrame: comp.containing_frame,
      },
      thumbnail: comp.thumbnail_url,
    }));
  }

  private parseStyles(styles: any): DesignAsset[] {
    if (!styles || !styles.meta?.styles) {
      return [];
    }

    return Object.entries(styles.meta.styles).map(([id, style]: [string, any]) => ({
      type: 'style',
      name: style.name,
      description: style.description,
      properties: {
        id,
        key: style.key,
        styleType: style.style_type,
      },
    }));
  }
}