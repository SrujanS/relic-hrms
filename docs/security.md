# Security baseline

1. Never expose Supabase service-role keys to browser code.
2. Keep RLS enabled for every tenant-owned table.
3. Test cross-tenant reads and writes using distinct authenticated users.
4. Restrict salary and payroll records to payroll-authorized roles.
5. Use private object storage for employee documents.
6. Keep personal data out of logs and analytics.
7. Add rate limits and abuse protections before public launch.
8. Establish privacy notices, data retention, export, deletion, and incident procedures.
9. Use synthetic data in development and AI prompts.
10. Obtain independent security and Indian payroll/compliance review before production use.

11. Attendance and leave requests must be visible only to HR/admin and the linked employee; verify this with separate user sessions.
