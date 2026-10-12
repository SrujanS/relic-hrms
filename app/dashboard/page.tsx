import Link from "next/link";
import { redirect } from "next/navigation";
import { requireUser, getFirstMembership } from "@/lib/auth";
import { signOut } from "./actions";

export default async function DashboardPage() {
  const { supabase, user } = await requireUser();
  const membership = await getFirstMembership(supabase);

  if (!membership) redirect("/company/new");

  const tenantId = membership.tenant_id;
  const tenant = Array.isArray(membership.tenants) ? membership.tenants[0] : membership.tenants;

  const [{ count: employeeCount }, { count: activeCount }] = await Promise.all([
    supabase.from("employees").select("id", { count: "exact", head: true }).eq("tenant_id", tenantId),
    supabase.from("employees").select("id", { count: "exact", head: true }).eq("tenant_id", tenantId).eq("employment_status", "active")
  ]);

  const { data: recentEmployees } = await supabase
    .from("employees")
    .select("id, employee_code, first_name, last_name, work_email, employment_status, joining_date")
    .eq("tenant_id", tenantId)
    .order("created_at", { ascending: false })
    .limit(5);

  return (
    <>
      <header className="topbar">
        <div className="topbar-inner">
          <div className="brand">Relic <span>HRMS</span></div>
          <nav className="navlinks">
            <Link href="/dashboard">Dashboard</Link>
            <Link href="/employees">Employees</Link>
            <Link href="/company/new">Company settings</Link>
            <form action={signOut}><button className="btn btn-secondary" type="submit">Sign out</button></form>
          </nav>
        </div>
      </header>
      <main className="container">
        <h1 className="heading">Dashboard</h1>
        <p className="subheading">Welcome, {user.email}. Workspace: <strong>{tenant && "name" in tenant ? tenant.name : "Your company"}</strong></p>
        <section className="grid">
          <article className="panel"><div className="muted">Total employees</div><div className="stat">{employeeCount ?? 0}</div></article>
          <article className="panel"><div className="muted">Active employees</div><div className="stat">{activeCount ?? 0}</div></article>
          <article className="panel"><div className="muted">Your role</div><div className="stat" style={{ fontSize: 22, textTransform: "capitalize" }}>{membership.role}</div></article>
        </section>
        <section className="panel" style={{ marginTop: 18 }}>
          <div style={{ display: "flex", justifyContent: "space-between", gap: 12, alignItems: "center", marginBottom: 12 }}>
            <h2 style={{ margin: 0, fontSize: 18 }}>Recently added employees</h2>
            <Link className="btn" href="/employees">Employee directory</Link>
          </div>
          <div className="tablewrap">
            <table>
              <thead><tr><th>Employee ID</th><th>Name</th><th>Work email</th><th>Status</th><th>Joining date</th></tr></thead>
              <tbody>
                {(recentEmployees ?? []).map(employee => (
                  <tr key={employee.id}>
                    <td>{employee.employee_code}</td>
                    <td>{employee.first_name} {employee.last_name}</td>
                    <td>{employee.work_email ?? "—"}</td>
                    <td><span className="badge">{employee.employment_status}</span></td>
                    <td>{employee.joining_date ?? "—"}</td>
                  </tr>
                ))}
                {(!recentEmployees || recentEmployees.length === 0) && <tr><td colSpan={5} className="muted">No employees yet. Add your first employee from the directory.</td></tr>}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </>
  );
}
