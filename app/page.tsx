import Link from "next/link";

export default function HomePage() {
  return (
    <>
      <header className="topbar">
        <div className="topbar-inner">
          <div className="brand">Relic <span>HRMS</span></div>
          <nav className="navlinks">
            <Link href="/login">Sign in</Link>
            <Link href="/signup">Create account</Link>
          </nav>
        </div>
      </header>
      <main className="container">
        <section className="panel" style={{ padding: "clamp(24px, 6vw, 64px)" }}>
          <span className="badge">HRIS · Attendance · Leave · Onboarding</span>
          <h1 className="heading" style={{ fontSize: "clamp(32px, 5vw, 48px)", marginTop: 18 }}>
            People operations, <br />in one place.
          </h1>
          <p className="subheading" style={{ maxWidth: 620 }}>
            Relic HRMS is a practical workspace for employee records and everyday HR workflows.
            Start with your company, invite your team, and build from a secure foundation.
          </p>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
            <Link className="btn" href="/signup">Get started</Link>
            <Link className="btn btn-secondary" href="/login">Sign in</Link>
          </div>
        </section>
        <section className="grid" style={{ marginTop: 18 }}>
          {[
            ["Core HRIS", "Employee directory, departments, and employment records."],
            ["Attendance & leave", "A foundation for attendance logs, leave requests, and approvals."],
            ["Recruitment & onboarding", "Track candidates and manage joining checklists."]
          ].map(([title, description]) => (
            <article className="panel" key={title}>
              <h2 style={{ fontSize: 18, marginTop: 0 }}>{title}</h2>
              <p className="muted" style={{ lineHeight: 1.6, marginBottom: 0 }}>{description}</p>
            </article>
          ))}
        </section>
      </main>
    </>
  );
}
