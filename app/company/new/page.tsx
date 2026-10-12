import { redirect } from "next/navigation";
import { requireUser, getFirstMembership } from "@/lib/auth";
import CompanyForm from "@/components/company-form";

export default async function NewCompanyPage() {
  const { supabase } = await requireUser();
  const membership = await getFirstMembership(supabase);
  if (membership) redirect("/dashboard");

  return (
    <main className="container" style={{ maxWidth: 640, paddingTop: 48 }}>
      <div className="brand" style={{ marginBottom: 28 }}>Relic <span>HRMS</span></div>
      <section className="panel">
        <h1 className="heading">Set up your company</h1>
        <p className="subheading">This creates your private company workspace. You will become its Company Admin.</p>
        <CompanyForm />
      </section>
    </main>
  );
}
