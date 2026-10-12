# Test plan

## Unit tests
- Input validation
- Employee ID normalization and duplicate handling
- Leave date boundaries and approval state transitions
- Payroll arithmetic and rounding (when payroll engine is implemented)

## Integration tests
- Sign-in and session expiry
- Company creation RPC
- Employee create/read/update under allowed roles
- RLS isolation across two tenants
- Payroll access denied to employee and manager roles

## End-to-end tests
- Register → sign in → create company → add employee
- Unauthorized role cannot add employee
- Tenant A cannot see or modify Tenant B records
- Invalid employee data is rejected with safe errors

## Release gate
No production employee data until all security tests pass and backups have been restored successfully in a test environment.
