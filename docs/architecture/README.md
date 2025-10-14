# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for significant architectural decisions in the `wolskies.infrastructure` collection.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences.

ADRs help us:
- **Remember why** decisions were made
- **Communicate** architectural choices to team members
- **Review** past decisions in light of new information
- **Document** the evolution of the architecture

## Format

Each ADR follows this structure:

1. **Title**: ADR-NNN: Descriptive Title
2. **Status**: Proposed | Accepted | Deprecated | Superseded
3. **Context**: What is the issue we're facing?
4. **Decision**: What decision did we make?
5. **Consequences**: What are the results of this decision?
6. **Alternatives Considered**: What other options did we evaluate?

## Index

### Active ADRs

- [ADR-001: Dynamic Service Orchestration with `configure_services`](./ADR-001-dynamic-service-orchestration.md) - **Proposed**
  - Introduces Phase 3: Services to the collection architecture
  - Establishes service interface contract pattern
  - Related Issue: [Implementation checklist](./ISSUE-configure-services-implementation.md)

## Process

### Creating a New ADR

1. Copy the template (create one if it doesn't exist)
2. Number it sequentially (ADR-NNN)
3. Set status to "Proposed"
4. Fill in all sections
5. Create a PR/MR for review
6. Update status to "Accepted" when implemented

### Updating an ADR

ADRs are **immutable once accepted**. If a decision needs to change:

1. Create a new ADR that supersedes the old one
2. Update the old ADR's status to "Superseded by ADR-NNN"
3. Link the new ADR to the old one

## Status Definitions

- **Proposed**: Decision is proposed but not yet implemented
- **Accepted**: Decision is accepted and implemented
- **Deprecated**: Decision is no longer recommended but still in use
- **Superseded**: Decision has been replaced by a newer ADR

## References

- [Architecture Decision Records (adr.github.io)](https://adr.github.io/)
- [ADR Tools](https://github.com/npryce/adr-tools)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
