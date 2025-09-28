## Thinking Modes

  ### Core Thinking Flags
  - **--think**: Multi-file analysis with context awareness (4K tokens)
    - Activates deeper analysis across multiple files
    - Considers interdependencies and broader context
    - Ideal for feature implementation and moderate complexity tasks

  - **--think-hard**: Deep architectural analysis (10K tokens)
    - Comprehensive system-wide analysis
    - Evaluates architectural patterns and design decisions
    - Explores multiple solution paths with trade-offs
    - Best for complex refactoring and system design

  - **--ultrathink**: Critical system redesign (32K tokens)
    - Maximum depth analysis for critical decisions
    - Complete architectural exploration
    - Exhaustive consideration of alternatives
    - Reserved for major system changes and critical problem-solving

  ### Auto-Activation Triggers
  Automatically activate thinking modes when detecting:
  - Multi-file dependencies → --think
  - Architectural decisions → --think-hard
  - System-wide changes → --ultrathink
  - Complex debugging scenarios → --think-hard
  - Security analysis → --ultrathink
  - Performance optimization → --think-hard

  ### Integration Patterns
  - **--think + --introspect**: Transparent multi-file reasoning
  - **--think-hard + --introspect**: Visible architectural decision-making
  - **--ultrathink + --introspect**: Complete cognitive transparency
  - **--think + sequential**: Step-by-step multi-file analysis
  - **--think-hard + sequential**: Progressive deep analysis
  - **--ultrathink + sequential**: Exhaustive systematic exploration

  ### Progressive Escalation
  1. Start with base analysis
  2. If complexity detected → auto-suggest --think
  3. If architectural impact → auto-suggest --think-hard
  4. If critical/security → auto-suggest --ultrathink

  ### Token Economics
  - Default mode: Minimal tokens, direct solutions
  - --think: 4K token budget for broader context
  - --think-hard: 10K token budget for deep analysis
  - --ultrathink: 32K token budget for comprehensive exploration

  ### Usage Examples
  - Bug fix in single file: No flag needed
  - Feature touching 3+ files: Use --think
  - Refactoring core module: Use --think-hard
  - Redesigning authentication: Use --ultrathink
  - Security audit: Use --ultrathink
  - Performance optimization: Use --think-hard

  ### Cognitive Scaling Rules
  1. Match thinking depth to problem complexity
  2. Prefer minimal effective depth (token economy)
  3. Escalate when initial analysis reveals complexity
  4. Document reasoning for depth selection
  5. Combine with --introspect for transparency when needed