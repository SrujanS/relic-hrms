 "use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/browser";

function makeSlug(value: string) {
  return value.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 48);
}

export default function CompanyForm() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const supabase = createClient();
    const { error } = await supabase.rpc("create_company", {
      company_name: name.trim(),
      company_slug: makeSlug(name)
    });
    setBusy(false);
    if (error) return setError(error.message);
    router.replace("/dashboard");
    router.refresh();
  }

  return (
    <form className="formstack" onSubmit={onSubmit}>
      {error && <p className="error" role="alert">{error}</p>}
      <div>
        <label className="label" htmlFor="company">Company name</label>
        <input className="field" id="company" value={name} onChange={e => setName(e.target.value)} minLength={2} maxLength={100} required />
      </div>
      <button className="btn" disabled={busy} type="submit">{busy ? "Creating workspace…" : "Create company workspace"}</button>
    </form>
  );
}
