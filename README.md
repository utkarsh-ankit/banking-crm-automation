# Banking CRM Cards — Agentic Support Automation

An end-to-end **agentic workflow** built in [n8n](https://n8n.io/) that automates banking card-replacement support tickets — from intake, to policy-compliant decisioning, to fulfillment and audit logging — with an LLM agent grounded in real company policy via RAG.

## Demo

📹 **Video walkthrough:** https://www.youtube.com/watch?v=-4b4aXTyD_o

## Overview

Card replacement requests are high-volume but still require judgment: VIP customers need white-glove handling, fee waivers are capped by policy, temporary-address shipments require fraud checks, and every decision needs to be traceable. This workflow handles that end-to-end with minimal human intervention, escalating to a human only where policy requires it.

Rather than hardcoding business rules, the agent is given a **retrieval tool** over the actual banking SOP documents, so its decisions (fee waiver, verification requirements, routing tier) are grounded in real policy text instead of hallucinated logic.

## Features

- **Multi-channel intake** — accepts tickets via an authenticated webhook (API) or by polling a Gmail inbox for subject-tagged support emails
- **Rate limiting** — per-sender request throttling via Redis before any ticket is processed
- **Payload normalization** — a single code node reconciles the two very different input shapes (webhook JSON vs. Gmail snippet) into one common schema
- **LLM agent decisioning** — an AI agent classifies each ticket for urgency, routing tier, fee-waiver eligibility, required verification, and drafts a customer reply, returned as strict structured JSON
- **RAG-grounded policy lookup** — the agent has a retrieval tool backed by a Qdrant vector store containing the actual banking SOPs, so waiver/verification decisions cite real policy
- **Tiered routing:**
  - **VIP / Priority Concierge** → instant Slack escalation to the support team
  - **Premium** → waiver history checked against Postgres; auto-approved if under the annual waiver cap, otherwise a payment-required draft is generated
  - **Standard** → a Jira ticket is filed and a Gmail draft reply is prepared for agent review
- **Fulfillment automation** — shipping label generation via HTTP request, with SMS notification to the customer via Twilio
- **Central audit log** — every ticket, regardless of path, is logged to a Google Sheet for compliance and traceability
- **Separate ingestion pipeline** — a manually-triggered flow chunks/embeds the SOP document and upserts it into the Qdrant knowledge base, so policy can be updated independently of the live workflow

## Architecture

```
                     ┌────────────┐     ┌────────────┐
   Webhook (API) ───▶│   Redis    │────▶│ Normalize  │
   Gmail Trigger ───▶│Rate Limiter│     │  Payload   │
                     └────────────┘     └─────┬──────┘
                                               ▼
                                        ┌─────────────┐        ┌──────────────────┐
                                        │  AI Agent   │◀──────▶│ RAG: Banking SOPs │
                                        │  (LLM)      │        │  (Qdrant + embed) │
                                        └──────┬──────┘        └──────────────────┘
                                               ▼
                                          ┌─────────┐
                                          │ Switch  │
                                          └────┬────┘
                     ┌────────────────────────┼────────────────────────┐
                     ▼                        ▼                        ▼
              VIP Track                Premium Track             Standard Track
           (Slack escalation)     (Postgres waiver check →   (Jira ticket + Gmail
                                    Auto-Approve / Payment      draft reply)
                                    Required → Shipping →
                                    SMS via Twilio)
                     │                        │                        │
                     └────────────────────────┴────────────────────────┘
                                               ▼
                                       Central Audit Log
                                        (Google Sheets)
```

Separately, an on-demand **Ingestion Workflow** loads the SOP document, embeds it, and upserts it into the same Qdrant collection the agent retrieves from at runtime.

## Tech Stack

| Component | Tool |
|---|---|
| Orchestration | n8n |
| LLM / Agent | Google Gemini (via LangChain nodes) |
| Vector store | Qdrant |
| Rate limiting | Redis |
| Relational data | Postgres |
| Ticketing | Jira |
| Messaging | Slack, Twilio (SMS) |
| Email | Gmail (trigger + draft creation) |
| Audit trail | Google Sheets |

## Prerequisites

You'll need accounts/credentials for:

- n8n (self-hosted or cloud)
- Google Gemini API (chat model + embeddings)
- Qdrant (cloud or self-hosted instance)
- Redis
- Postgres
- Gmail (OAuth2)
- Slack (bot token with access to your target channel)
- Jira Cloud
- Twilio
- Google Sheets (OAuth2)

## Setup

1. Import `workflow.json` into your n8n instance.
2. Configure each credential in n8n's Credentials panel — the workflow references them by name, so either reuse those names or update the nodes after import.
3. Run the **Ingestion Workflow** once (manual trigger) to embed the SOP document into Qdrant before going live.
4. Update the following node parameters for your environment:
   - Webhook path / header-auth credential
   - Gmail search filter (currently `subject:"Ticket"`)
   - Slack channel (`#agentic-stuff`)
   - Jira project / issue type
   - Google Sheet ID for the audit log
   - Postgres query (currently scoped to a placeholder customer ID for demo purposes)
5. Activate the workflow.

## Notes

- The AI Agent is instructed to return **strict JSON only** (no markdown/prose) so downstream nodes can parse its output directly — this is enforced via the system prompt.
- The Switch node's tier routing, the Postgres waiver check, and the RAG tool are what keep this from being a "chatbot with extra steps" — the agent's decisions are checked against real data and real policy at each step, not just its own judgment.
- An `errorWorkflow` is configured at the workflow level to catch failures centrally.
