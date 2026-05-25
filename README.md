# Business Ops Intelligence Hub

A self-hosted small-business analytics automation system for a small e-commerce business, combining structured BI dashboards with AI-powered document/search context.


This project demonstrates how a small business can collect operational data, clean it automatically, store it in Postgres, visualize it in Metabase, and later enrich it with vector search and an AI assistant.

## Project Concept

Every day, a small business creates useful data:

- orders
- customers
- products
- leads
- competitor prices
- customer feedback
- product descriptions

Instead of keeping this data scattered across CSV files and spreadsheets, this project creates an automated workflow:

```text
Source data → n8n → Postgres → Metabase → Business decisions

Later extension:
Documents / feedback / product text → Vector database → AI assistant