import Link from "next/link";
import { requireUser, getFirstMembership } from "@/lib/auth";
import { redirect } from "next/navigation";
import EmployeeForm from "@/components/employee-form";
import { createEmployee } from "./actions";

export default async function EmployeesPage() {
  const { supabase } = await requireUser();
  const membership = await getFirstMembership(supabase);
  if (!membership) redirect("/company/new");

  const tenantId = membership.tenant_id;
  const { data: employees, error } = await supabase
    .from("employees")
    .select("id, employee_code, first_name, last_name, work_email, department_id, employment_status, joining_date")
    .eq("tenant_id", tenantId)
    .order("created_at", { ascending: false });

  const canManage = ["company_admin", "hr_admin"].includes(membership.role);

  return (
    <>
      <header className="topbar">
        <div className="topbar-inner">
          <div className="brand">Relic <span>HRMS</span></div>
          <nav className="navlinks"><Link href="/dashboard">Dashboard</Link><Link href="/employees">Employees</Link></nav>
        </div>
      </header>
      <main className="container">
        <h1 className="heading">Employee directory</h1>
        <p className="subheading">Manage employee records for your current company workspace.</p>
        {error && <p className="error">Could not load employees. Check your schema and access policies.</p>}
        <div className="grid" style={{ gridTemplateColumns: canManage ? "minmax(260px, 1fr) minmax(0, 2fr)" : "1fr", alignItems: "start" }}>
          {canManage && <section className="panel">
            <h2 style={{ marginTop: 0, fontSize: 18 }}>Add employee</h2>
            <EmployeeForm action={createEmployee} />
          </section>}
          <section className="panel">
            <h2 style={{ marginTop: 0, fontSize: 18 }}>Employees ({employees?.length ?? 0})</h2>
            <div className="tablewrap">
              <table>
                <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Status</th><th>Joining date</th></tr></thead>
                <tbody>
                  {(employees ?? []).map(e => <tr key={e.id}>
                    <td>{e.employee_code}</td><td>{e.first_name} {e.last_name}</td><td>{e.work_email ?? "—"}</td>
                    <td><span className="badge">{e.employment_status}</span></td><td>{e.joining_date ?? "—"}</td>
                  </tr>)}
                  {(!employees || employees.length === 0) && <tr><td colSpan={5} className="muted">No employee records found.</td></tr>}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </main>
    </>
  );
}
