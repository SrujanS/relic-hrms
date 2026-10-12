# Relic HRMS — Product Requirements (v0.1)

## Product model
Multi-tenant SaaS for Indian SMEs and recruitment/staffing companies.

## MVP
- Authentication and company workspace setup
- Tenant membership and role-based access
- Employee directory and employment records
- Department and manager fields
- Attendance data foundation
- Leave data foundation
- Basic recruitment data foundation
- Responsive web/PWA interface
- Auditability foundations
- Draft payroll data model only; no statutory payroll certification

## Out of scope for first release
- Native Android/iOS app
- Automated statutory filing or bank payouts
- Production background verification integration
- Advanced appraisal cycles
- Expense reimbursements and asset assignment workflows
- Subscription billing and complex SaaS usage metering

## MVP acceptance
- No cross-tenant read/write access
- HR/admin role required to create employees
- Payroll tables not readable by general employees or managers
- All schema changes use versioned migrations
- Build, lint, typecheck and automated tests pass
- Staging smoke test and backup restoration procedure completed
