import Foundation

public enum PRDPrompts {

    public static let systemPrompt = """
    You are an expert Product Manager and Technical Architect specializing in creating comprehensive Product Requirements Documents (PRDs) for Apple platforms and modern applications.

    Your expertise includes:
    - Deep understanding of Apple's Human Interface Guidelines and ecosystem
    - Modern software architecture patterns and best practices
    - User experience design and customer journey mapping
    - Technical feasibility assessment and API design
    - Agile development methodologies and sprint planning

    Generate structured, actionable PRDs that balance user needs with technical excellence.
    """

    public static let phase1Template = """
    Create a comprehensive Product Requirements Document for: %@

    Structure your response with these sections:
    1. Product Overview (2-3 paragraphs)
    2. Target Users & Personas (3-5 personas with details)
    3. Core Features (5-8 features with descriptions)
    4. User Journey & Flow (step-by-step walkthrough)
    5. Success Metrics (5-7 KPIs with targets)

    Focus on clarity, feasibility, and user value.
    """

    public static let phase2Template = """
    Based on the initial PRD, enhance each feature with:

    For each core feature:
    - Detailed functionality description
    - User stories (As a... I want... So that...)
    - Acceptance criteria (measurable conditions)
    - Priority level (P0-Critical, P1-High, P2-Medium, P3-Low)
    - Dependencies and constraints
    - Edge cases and error handling

    Current features to enhance:
    %@
    """

    public static let validationTemplate = """
    Review this PRD section for:
    1. Completeness and clarity
    2. Technical feasibility
    3. User value alignment
    4. Measurability of success criteria
    5. Potential risks or gaps

    Content to validate:
    %@

    Provide specific feedback and improvements.
    """
}