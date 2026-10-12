# Relic HRMS — Starter Kit

A starter codebase for a multi-tenant HRMS/HRIS SaaS using Next.js App Router, TypeScript, Supabase Auth, PostgreSQL and Row-Level Security (RLS).

## Included
- Email/password sign-in
- Company creation RPC and tenant membership
- Employee directory and create-employee flow
- Initial tenant-scoped schema for departments, attendance, leave, employee documents and audit events
- PostgreSQL RLS policies and automated-test starting points
- Responsive starter UI

## Not production-certified
This is a development foundation, not a finished HRMS. Before real employee or payroll data is used, conduct a security review, verify all RLS policies, implement comprehensive tests, privacy/retention controls, backup recovery, and payroll compliance validation. Payroll in this starter is intentionally not implemented.

## Requirements
- Node.js 20+
- npm
- A Supabase project

## Setup
1. Create a Supabase project.
2. In Supabase SQL Editor, run `supabase/migrations/0001_initial_schema.sql`.
3. Copy `.env.example` to `.env.local`.
4. Add the Supabase project URL and publishable/anon key.
5. Install and run:

   ```bash
   npm install
   npm run dev
   ```

6. Open http://localhost:3000.
7. Create an account, verify email if Supabase requires it, sign in, and create a company.

## Important Supabase Auth setting
For local development, configure the Site URL and redirect URLs in Supabase Auth. Add:
- `http://localhost:3000/**`
- your future staging and production URLs

If email confirmation is enabled, complete the confirmation step before signing in.

## First release scope
The UI supports company setup and basic employee records. Attendance, leave, recruitment, onboarding, expenses, assets, performance, native mobile, and compliant payroll are schema/planning foundations only; they still require implementation and tests.

## Security principles
- Never commit `.env.local`.
- Never put a Supabase service-role key in the browser or any `NEXT_PUBLIC_*` variable.
- Keep RLS enabled for every tenant-owned table. Employee records are readable by HR/admin or the employee linked to that record; manager team access requires a separately reviewed policy.
- Do not rely on UI checks for authorization.
- Use synthetic data until security testing is complete.
- Do not store Aadhaar, bank details, CVs, or real employee information in AI prompts.
- Use a separate staging project; do not test migrations against production first.

## Useful commands
```bash
npm run dev
npm run lint
npm run typecheck
npm run build
```

## Suggested next development increments
1. Add integration tests for tenant isolation and membership roles.
2. Implement departments, attendance and leave actions with approval transitions.
3. Add private document storage with file type/size validation and signed URLs.
4. Add recruitment and onboarding.
5. Implement a payroll calculation engine only after a compliance expert signs off on the rule model.
