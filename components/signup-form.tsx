 "use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/browser";

export default function SignupForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage("");
    setError("");
    setBusy(true);
    const supabase = createClient();
    const { data, error } = await supabase.auth.signUp({ email, password });
    setBusy(false);
    if (error) return setError(error.message);
    if (!data.session) {
      setMessage("Account created. Check your email to confirm the account, then sign in.");
    } else {
      setMessage("Account created. You can now sign in and create your company workspace.");
    }
  }

  return (
    <form className="formstack" onSubmit={onSubmit}>
      {error && <p className="error" role="alert">{error}</p>}
      {message && <p className="success" role="status">{message}</p>}
      <div>
        <label className="label" htmlFor="email">Work email</label>
        <input className="field" id="email" type="email" autoComplete="email" required value={email} onChange={e => setEmail(e.target.value)} />
      </div>
      <div>
        <label className="label" htmlFor="password">Password (minimum 8 characters)</label>
        <input className="field" id="password" type="password" autoComplete="new-password" required minLength={8} value={password} onChange={e => setPassword(e.target.value)} />
      </div>
      <button className="btn" disabled={busy} type="submit">{busy ? "Creating account…" : "Create account"}</button>
      <p className="muted" style={{ fontSize: 14, margin: 0 }}>Already registered? <Link href="/login" style={{ color: "var(--brand)", fontWeight: 700 }}>Sign in</Link></p>
    </form>
  );
}
