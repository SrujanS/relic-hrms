import LoginForm from "@/components/login-form";

export default function LoginPage() {
  return (
    <main className="container" style={{ maxWidth: 520, paddingTop: 64 }}>
      <div className="brand" style={{ marginBottom: 28 }}>Relic <span>HRMS</span></div>
      <section className="panel">
        <h1 className="heading">Welcome back</h1>
        <p className="subheading">Sign in to your HR workspace.</p>
        <LoginForm />
      </section>
    </main>
  );
}
