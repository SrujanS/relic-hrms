 "use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/browser";

export default function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) return setError(error.message);
    router.replace("/dashboard");
    router.refresh();
  }

  return (
    <form className="formstack" onSubmit={onSubmit}>
      {error && <p className="error" role="alert">{error}</p>}
      <div>
        <label className="label" htmlFor="email">Work email</label>
        <input className="field" id="email" type="email" autoComplete="email" required value={email} onChange={e => setEmail(e.target.value)} />
      </div>
      <div>
        <label className="label" htmlFor="password">Password</label>
        <input className="field" id="password" type="password" autoComplete="current-password" required minLength={8} value={password} onChange={e => setPassword(e.target.value)} />
      </div>
      <button className="btn" disabled={busy} type="submit">{busy ? "Signing in…" : "Sign in"}</button>
      <p className="muted" style={{ fontSize: 14, margin: 0 }}>New to Relic HRMS? <Link href="/signup" style={{ color: "var(--brand)", fontWeight: 700 }}>Create an account</Link></p>
    </form>
  );
}
