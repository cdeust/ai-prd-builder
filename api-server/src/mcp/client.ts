import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import { spawn } from 'child_process';

export interface MCPTool {
  name: string;
  description?: string;
  inputSchema?: any;
}

export interface MCPResource {
  uri: string;
  name: string;
  description?: string;
  mimeType?: string;
}

export class MCPClient {
  private client: Client;
  private transport: StdioClientTransport;
  private connected: boolean = false;

  constructor(
    private serverPath: string,
    private serverArgs: string[] = []
  ) {
    this.client = new Client({
      name: 'ai-provider-api',
      version: '1.0.0',
    }, {
      capabilities: {}
    });
  }

  async connect(): Promise<void> {
    if (this.connected) return;

    const childProcess = spawn(this.serverPath, this.serverArgs, {
      env: { ...process.env },
    });

    this.transport = new StdioClientTransport({
      command: this.serverPath,
      args: this.serverArgs,
      env: process.env as Record<string, string>,
    });

    await this.client.connect(this.transport);
    this.connected = true;
  }

  async disconnect(): Promise<void> {
    if (!this.connected) return;
    await this.client.close();
    this.connected = false;
  }

  async listTools(): Promise<MCPTool[]> {
    if (!this.connected) await this.connect();
    const response = await this.client.listTools();
    return response.tools;
  }

  async listResources(): Promise<MCPResource[]> {
    if (!this.connected) await this.connect();
    const response = await this.client.listResources();
    return response.resources;
  }

  async callTool(name: string, args: any = {}): Promise<any> {
    if (!this.connected) await this.connect();
    const response = await this.client.callTool({
      name,
      arguments: args,
    });
    return response.content;
  }

  async readResource(uri: string): Promise<string> {
    if (!this.connected) await this.connect();
    const response = await this.client.readResource({ uri });
    return response.contents[0]?.text || '';
  }
}