import SignupForm from "@/components/signup-form";

export default function SignupPage() {
  return (
    <main className="container" style={{ maxWidth: 560, paddingTop: 48 }}>
      <div className="brand" style={{ marginBottom: 28 }}>Relic <span>HRMS</span></div>
      <section className="panel">
        <h1 className="heading">Create your account</h1>
        <p className="subheading">Register a user account, then create your company workspace.</p>
        <SignupForm />
      </section>
    </main>
  );
}
