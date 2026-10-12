 "use client";

import { useActionState } from "react";

type FormState = { error?: string; success?: string };
const initialState: FormState = {};

export default function EmployeeForm({ action }: { action: (state: FormState, formData: FormData) => Promise<FormState> }) {
  const [state, formAction, pending] = useActionState(action, initialState);

  return (
    <form className="formstack" action={formAction}>
      {state.error && <p className="error" role="alert">{state.error}</p>}
      {state.success && <p className="success" role="status">{state.success}</p>}
      <div><label className="label" htmlFor="employee_code">Employee ID</label><input className="field" id="employee_code" name="employee_code" maxLength={32} required /></div>
      <div><label className="label" htmlFor="first_name">First name</label><input className="field" id="first_name" name="first_name" maxLength={80} required /></div>
      <div><label className="label" htmlFor="last_name">Last name</label><input className="field" id="last_name" name="last_name" maxLength={80} required /></div>
      <div><label className="label" htmlFor="work_email">Work email</label><input className="field" id="work_email" name="work_email" type="email" maxLength={254} /></div>
      <div><label className="label" htmlFor="joining_date">Joining date</label><input className="field" id="joining_date" name="joining_date" type="date" /></div>
      <button className="btn" type="submit" disabled={pending}>{pending ? "Saving…" : "Add employee"}</button>
    </form>
  );
}
