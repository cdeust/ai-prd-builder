# Domain Configuration System

## Overview

The domain configuration system allows for external, maintainable domain definitions without modifying Swift code. All domain-specific knowledge is stored in JSON configuration files that can be easily updated by domain experts, product managers, or developers.

## Configuration Structure

### Main Configuration File: `domains.json`

The configuration file contains:

```json
{
  "domains": {
    "domain_key": {
      "name": "Human-readable name",
      "priority": 1,  // Lower number = higher priority for detection
      "indicators": ["keywords", "for", "detection"],
      "guidance": {
        "sections": [
          {
            "title": "Section Title",
            "items": ["Guidance item 1", "Guidance item 2"]
          }
        ]
      },
      "questions": ["Domain-specific question 1", "Question 2"],
      "requirements_checklist": ["Required item 1", "Required item 2"],
      "metrics": [
        {
          "name": "Metric Name",
          "unit": "percentage|milliseconds|count|etc",
          "target": ">95%|<500ms|etc",
          "critical": true
        }
      ]
    }
  },
  "fallback": {
    // Default configuration when no domain matches
  }
}
```

## Adding a New Domain

1. Add a new entry to the `domains` object in `domains.json`
2. Define the following required fields:
   - `name`: Display name for the domain
   - `priority`: Detection priority (1 = highest)
   - `indicators`: Keywords that trigger this domain
   - `guidance`: Structured guidance for PRD creation
   - `questions`: Domain-specific questions to ask
   - `requirements_checklist`: Common requirements often missed
   - `metrics`: Key performance indicators for this domain

### Example: Adding a Gaming Domain

```json
"gaming": {
  "name": "Gaming & Entertainment",
  "priority": 6,
  "indicators": [
    "game", "player", "multiplayer", "leaderboard", "achievement",
    "score", "level", "character", "inventory", "matchmaking"
  ],
  "guidance": {
    "sections": [
      {
        "title": "GAME MECHANICS",
        "items": [
          "Core gameplay loop definition",
          "Progression system design",
          "Balancing and difficulty curves",
          "Reward and achievement systems"
        ]
      },
      {
        "title": "MULTIPLAYER REQUIREMENTS",
        "items": [
          "Matchmaking algorithms",
          "Anti-cheat measures",
          "Server architecture",
          "Latency compensation"
        ]
      }
    ]
  },
  "questions": [
    "What type of game is this (mobile, console, PC)?",
    "Is it single-player, multiplayer, or both?",
    "What is the target audience age range?",
    "What monetization model will be used?",
    "What are the platform requirements?"
  ],
  "requirements_checklist": [
    "Game design document",
    "Technical architecture",
    "Anti-cheat system",
    "Analytics integration",
    "Monetization strategy",
    "Player data privacy"
  ],
  "metrics": [
    {
      "name": "Daily Active Users",
      "unit": "count",
      "target": ">10000",
      "critical": true
    },
    {
      "name": "Session Length",
      "unit": "minutes",
      "target": ">15",
      "critical": false
    }
  ]
}
```

## Modifying Existing Domains

1. Locate the domain key in `domains.json`
2. Update any fields as needed
3. No code changes required - changes take effect on next app launch

## Best Practices

### Domain Indicators
- Use specific, unique keywords
- Order matters: more specific domains should have higher priority (lower number)
- Avoid overlapping indicators between domains

### Guidance Sections
- Group related items into logical sections
- Use clear, actionable language
- Include compliance and regulatory requirements
- Cover technical, business, and user experience aspects

### Questions
- Start with high-level questions
- Progress to more specific details
- Include regulatory/compliance questions
- Ask about integrations and dependencies
- Cover scale and performance expectations

### Requirements Checklist
- Focus on commonly forgotten items
- Include security and compliance requirements
- Add documentation needs
- Cover testing and monitoring

### Metrics
- Use measurable, specific targets
- Mark critical metrics that block launch
- Include both technical and business metrics
- Use appropriate units (percentage, milliseconds, count, etc.)

## Testing Configuration Changes

After modifying `domains.json`:

1. Validate JSON syntax:
```bash
python3 -m json.tool domains.json > /dev/null && echo "Valid JSON"
```

2. Test domain detection:
```swift
// In your Swift code
let testText = "I need a payment processing system"
let detectedDomain = DomainKnowledge.detectDomain(from: testText)
print("Detected domain: \(detectedDomain)")
```

3. Verify guidance generation:
```swift
let guidance = DomainKnowledge.getDomainGuidance(for: detectedDomain, request: testText)
print(guidance)
```

## Configuration Loading

The system attempts to load configuration from these locations (in order):
1. Bundle resources (for packaged applications)
2. Source directory `DomainConfigurations/domains.json`
3. Project root `Configurations/domains.json`
4. Falls back to embedded default if file not found

## Maintenance Tips

- Review and update domain configurations quarterly
- Add new domains as new project types emerge
- Update metrics based on industry standards
- Keep questions relevant to current technology
- Update compliance requirements as regulations change

## Version Control

- Track changes to `domains.json` in git
- Document significant changes in commit messages
- Consider using semantic versioning for major updates
- Keep backups of previous configurations

## Contributing

When contributing domain configurations:
1. Ensure all required fields are present
2. Validate JSON syntax
3. Test domain detection with sample texts
4. Document the domain's purpose and use cases
5. Review with domain experts before merging