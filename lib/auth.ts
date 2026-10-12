import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export async function requireUser() {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) redirect("/login");
  return { supabase, user };
}

export async function getFirstMembership(supabase: Awaited<ReturnType<typeof createClient>>) {
  const { data, error } = await supabase
    .from("memberships")
    .select("tenant_id, role, tenants(id, name, slug)")
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (error) throw new Error("Could not load company membership.");
  return data;
}
