-- Relic HRMS initial schema.
-- Run in a fresh Supabase project. Review before production use.

create extension if not exists pgcrypto;

create type public.membership_role as enum (
  'company_admin', 'hr_admin', 'manager', 'payroll_officer', 'recruiter', 'employee'
);

create type public.membership_status as enum ('active', 'invited', 'suspended');
create type public.employment_status as enum ('active', 'probation', 'notice_period', 'exited', 'inactive');
create type public.leave_request_status as enum ('pending', 'approved', 'rejected', 'cancelled');

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 100),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  status text not null default 'active' check (status in ('active', 'suspended', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.membership_role not null default 'employee',
  status public.membership_status not null default 'active',
  created_at timestamptz not null default now(),
  unique (tenant_id, user_id),
  unique (id, tenant_id)
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  created_at timestamptz not null default now(),
  unique (tenant_id, name),
  unique (id, tenant_id)
);

create table public.employees (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  employee_code text not null check (char_length(employee_code) between 1 and 32),
  user_id uuid references auth.users(id) on delete set null,
  department_id uuid,
  manager_id uuid,
  first_name text not null check (char_length(first_name) between 1 and 80),
  last_name text not null check (char_length(last_name) between 1 and 80),
  work_email text,
  phone text,
  job_title text,
  employment_status public.employment_status not null default 'active',
  joining_date date,
  exit_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null,
  unique (tenant_id, employee_code),
  unique (id, tenant_id),
  foreign key (department_id, tenant_id) references public.departments(id, tenant_id),
  foreign key (manager_id, tenant_id) references public.employees(id, tenant_id),
  check (exit_date is null or joining_date is null or exit_date >= joining_date)
);

create unique index employees_tenant_work_email_unique
  on public.employees (tenant_id, lower(work_email))
  where work_email is not null;

create table public.employee_documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  employee_id uuid not null,
  document_type text not null check (char_length(document_type) between 1 and 80),
  storage_key text not null,
  original_filename text not null,
  content_type text,
  size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  foreign key (employee_id, tenant_id) references public.employees(id, tenant_id)
);

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  employee_id uuid not null,
  work_date date not null,
  check_in_at timestamptz,
  check_out_at timestamptz,
  status text not null default 'present' check (status in ('present', 'absent', 'half_day', 'holiday', 'weekly_off', 'leave', 'correction_pending')),
  source text not null default 'manual' check (source in ('manual', 'self_service', 'import', 'admin_correction')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (employee_id, tenant_id) references public.employees(id, tenant_id),
  unique (tenant_id, employee_id, work_date),
  check (check_out_at is null or check_in_at is null or check_out_at >= check_in_at)
);

create table public.leave_types (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  annual_allowance numeric(7,2) not null default 0 check (annual_allowance >= 0),
  carry_forward_allowed boolean not null default false,
  created_at timestamptz not null default now(),
  unique (tenant_id, name),
  unique (id, tenant_id)
);

create table public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  employee_id uuid not null,
  leave_type_id uuid not null,
  start_date date not null,
  end_date date not null,
  requested_days numeric(6,2) not null check (requested_days > 0),
  reason text,
  status public.leave_request_status not null default 'pending',
  approved_by uuid references auth.users(id) on delete set null,
  decision_note text,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (employee_id, tenant_id) references public.employees(id, tenant_id),
  foreign key (leave_type_id, tenant_id) references public.leave_types(id, tenant_id),
  check (end_date >= start_date)
);

create table public.job_openings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  title text not null,
  department_id uuid,
  location text,
  employment_type text,
  status text not null default 'draft' check (status in ('draft', 'open', 'on_hold', 'closed')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  foreign key (department_id, tenant_id) references public.departments(id, tenant_id),
  unique (id, tenant_id)
);

create table public.candidates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  full_name text not null,
  email text,
  phone text,
  consent_status text not null default 'not_recorded' check (consent_status in ('not_recorded', 'given', 'withdrawn')),
  created_at timestamptz not null default now(),
  unique (id, tenant_id)
);

create table public.candidate_applications (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  candidate_id uuid not null,
  job_opening_id uuid not null,
  stage text not null default 'applied' check (stage in ('applied', 'screening', 'interview', 'offer', 'hired', 'rejected', 'withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (candidate_id, tenant_id) references public.candidates(id, tenant_id),
  foreign key (job_opening_id, tenant_id) references public.job_openings(id, tenant_id),
  unique (candidate_id, job_opening_id)
);

create table public.salary_structures (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  employee_id uuid not null,
  effective_from date not null,
  effective_to date,
  currency char(3) not null default 'INR',
  components jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  foreign key (employee_id, tenant_id) references public.employees(id, tenant_id),
  check (effective_to is null or effective_to >= effective_from)
);

create table public.payroll_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  status text not null default 'draft' check (status in ('draft', 'calculating', 'review', 'approved', 'locked', 'cancelled')),
  rules_version text,
  approved_by uuid references auth.users(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  locked_at timestamptz,
  check (period_end >= period_start)
);

create table public.payroll_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  payroll_run_id uuid not null,
  employee_id uuid not null,
  gross_pay numeric(14,2) not null default 0 check (gross_pay >= 0),
  deductions numeric(14,2) not null default 0 check (deductions >= 0),
  net_pay numeric(14,2) not null default 0 check (net_pay >= 0),
  calculation_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  foreign key (payroll_run_id, tenant_id) references public.payroll_runs(id, tenant_id),
  foreign key (employee_id, tenant_id) references public.employees(id, tenant_id),
  unique (payroll_run_id, employee_id)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index memberships_user_status_idx on public.memberships(user_id, status);
create index employees_tenant_status_idx on public.employees(tenant_id, employment_status);
create index attendance_tenant_date_idx on public.attendance_records(tenant_id, work_date);
create index leave_requests_tenant_status_idx on public.leave_requests(tenant_id, status);
create index applications_tenant_stage_idx on public.candidate_applications(tenant_id, stage);
create index payroll_runs_tenant_period_idx on public.payroll_runs(tenant_id, period_start, period_end);

-- Helper functions use a controlled search_path and SECURITY DEFINER to avoid RLS recursion
-- when policies need to inspect memberships. These functions only answer membership questions.
create or replace function public.is_tenant_member(target_tenant uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.memberships m
    where m.tenant_id = target_tenant
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  );
$$;

create or replace function public.has_tenant_role(target_tenant uuid, allowed_roles public.membership_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.memberships m
    where m.tenant_id = target_tenant
      and m.user_id = (select auth.uid())
      and m.status = 'active'
      and m.role = any(allowed_roles)
  );
$$;

revoke all on function public.is_tenant_member(uuid) from public;
revoke all on function public.has_tenant_role(uuid, public.membership_role[]) from public;
grant execute on function public.is_tenant_member(uuid) to authenticated;
grant execute on function public.has_tenant_role(uuid, public.membership_role[]) to authenticated;

-- Secure company bootstrap: the caller becomes Company Admin for the newly created tenant.
create or replace function public.create_company(company_name text, company_slug text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_tenant_id uuid;
  clean_name text;
  clean_slug text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  clean_name := btrim(company_name);
  clean_slug := lower(btrim(company_slug));

  if char_length(clean_name) < 2 or char_length(clean_name) > 100 then
    raise exception 'Company name must be between 2 and 100 characters';
  end if;

  if clean_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or char_length(clean_slug) > 48 then
    raise exception 'Invalid company slug';
  end if;

  insert into public.tenants(name, slug)
  values (clean_name, clean_slug)
  returning id into new_tenant_id;

  insert into public.profiles(id, display_name)
  values (auth.uid(), null)
  on conflict (id) do nothing;

  insert into public.memberships(tenant_id, user_id, role, status)
  values (new_tenant_id, auth.uid(), 'company_admin', 'active');

  insert into public.audit_logs(tenant_id, actor_user_id, action, entity_type, entity_id)
  values (new_tenant_id, auth.uid(), 'company.created', 'tenant', new_tenant_id::text);

  return new_tenant_id;
end;
$$;

revoke all on function public.create_company(text, text) from public;
grant execute on function public.create_company(text, text) to authenticated;

-- Enable RLS on all tables.
alter table public.tenants enable row level security;
alter table public.profiles enable row level security;
alter table public.memberships enable row level security;
alter table public.departments enable row level security;
alter table public.employees enable row level security;
alter table public.employee_documents enable row level security;
alter table public.attendance_records enable row level security;
alter table public.leave_types enable row level security;
alter table public.leave_requests enable row level security;
alter table public.job_openings enable row level security;
alter table public.candidates enable row level security;
alter table public.candidate_applications enable row level security;
alter table public.salary_structures enable row level security;
alter table public.payroll_runs enable row level security;
alter table public.payroll_items enable row level security;
alter table public.audit_logs enable row level security;

-- Tenants and profiles.
create policy tenants_select_member on public.tenants
for select to authenticated using (public.is_tenant_member(id));

create policy profiles_select_self on public.profiles
for select to authenticated using (id = (select auth.uid()));
create policy profiles_insert_self on public.profiles
for insert to authenticated with check (id = (select auth.uid()));
create policy profiles_update_self on public.profiles
for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- Memberships: users can see their own memberships; company admins can see memberships in their tenant.
create policy memberships_select_self_or_admin on public.memberships
for select to authenticated using (
  user_id = (select auth.uid())
  or public.has_tenant_role(tenant_id, array['company_admin']::public.membership_role[])
);
create policy memberships_admin_insert on public.memberships
for insert to authenticated with check (
  public.has_tenant_role(tenant_id, array['company_admin']::public.membership_role[])
);
create policy memberships_admin_update on public.memberships
for update to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin']::public.membership_role[])
) with check (
  public.has_tenant_role(tenant_id, array['company_admin']::public.membership_role[])
);

-- Departments.
create policy departments_select_member on public.departments
for select to authenticated using (public.is_tenant_member(tenant_id));
create policy departments_manage_hr on public.departments
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]));

-- Employees: HR/admin can read company records; employees can read their own linked record.
-- Manager team access can be added after a reviewed reporting-line policy is implemented.
create policy employees_select_hr_or_self on public.employees
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[])
  or user_id = (select auth.uid())
);
create policy employees_insert_hr on public.employees
for insert to authenticated with check (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[])
);
create policy employees_update_hr on public.employees
for update to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]));

-- Employee documents: HR/admin can manage; employee self-access can be refined when employee-user linking is enabled.
create policy documents_select_hr on public.employee_documents
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin','payroll_officer']::public.membership_role[])
);
create policy documents_insert_hr on public.employee_documents
for insert to authenticated with check (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[])
);
create policy documents_delete_hr on public.employee_documents
for delete to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[])
);

-- Attendance: tenant members can read; HR/admin can manage. Self-service write is deliberately deferred
-- until an authenticated user is securely mapped to an employee record.
create policy attendance_select_hr_or_self on public.attendance_records
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[])
  or exists (
    select 1 from public.employees e
    where e.id = attendance_records.employee_id
      and e.tenant_id = attendance_records.tenant_id
      and e.user_id = (select auth.uid())
  )
);
create policy attendance_manage_hr on public.attendance_records
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]));

-- Leave.
create policy leave_types_select_member on public.leave_types
for select to authenticated using (public.is_tenant_member(tenant_id));
create policy leave_types_manage_hr on public.leave_types
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]));

create policy leave_requests_select_hr_or_self on public.leave_requests
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[])
  or exists (
    select 1 from public.employees e
    where e.id = leave_requests.employee_id
      and e.tenant_id = leave_requests.tenant_id
      and e.user_id = (select auth.uid())
  )
);
create policy leave_requests_manage_hr on public.leave_requests
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin']::public.membership_role[]));

-- Recruitment: recruiter/HR/admin access.
create policy jobs_select_member on public.job_openings
for select to authenticated using (public.is_tenant_member(tenant_id));
create policy jobs_manage_recruitment on public.job_openings
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[]));

create policy candidates_select_recruitment on public.candidates
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[])
);
create policy candidates_manage_recruitment on public.candidates
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[]));

create policy applications_select_recruitment on public.candidate_applications
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[])
);
create policy applications_manage_recruitment on public.candidate_applications
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','hr_admin','recruiter']::public.membership_role[]));

-- Payroll data is restricted to company admin and payroll officer, not general tenant members.
create policy salary_select_payroll on public.salary_structures
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[])
);
create policy salary_manage_payroll on public.salary_structures
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[]));

create policy payroll_runs_select_payroll on public.payroll_runs
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[])
);
create policy payroll_runs_manage_payroll on public.payroll_runs
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[]));

create policy payroll_items_select_payroll on public.payroll_items
for select to authenticated using (
  public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[])
);
create policy payroll_items_manage_payroll on public.payroll_items
for all to authenticated
using (public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[]))
with check (public.has_tenant_role(tenant_id, array['company_admin','payroll_officer']::public.membership_role[]));

-- Audit logs are readable by company admin only. Inserts are restricted to controlled server-side workflows
-- and SECURITY DEFINER functions; there is intentionally no client insert/update/delete policy.
create policy audit_select_admin on public.audit_logs
for select to authenticated using (
  tenant_id is not null
  and public.has_tenant_role(tenant_id, array['company_admin']::public.membership_role[])
);

-- Explicitly do not grant anonymous access.
revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
