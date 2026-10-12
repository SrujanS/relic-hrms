 "use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

type FormState = { error?: string; success?: string };

const employeeSchema = z.object({
  employee_code: z.string().trim().min(1).max(32).regex(/^[A-Za-z0-9_-]+$/),
  first_name: z.string().trim().min(1).max(80),
  last_name: z.string().trim().min(1).max(80),
  work_email: z.union([z.literal(""), z.string().trim().email().max(254)]),
  joining_date: z.union([z.literal(""), z.string().date()])
});

export async function createEmployee(_previousState: FormState, formData: FormData): Promise<FormState> {
  const parsed = employeeSchema.safeParse({
    employee_code: formData.get("employee_code"),
    first_name: formData.get("first_name"),
    last_name: formData.get("last_name"),
    work_email: formData.get("work_email") ?? "",
    joining_date: formData.get("joining_date") ?? ""
  });

  if (!parsed.success) return { error: "Please check the employee details and try again." };

  const supabase = await createClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return { error: "Your session has expired. Please sign in again." };

  const { data: membership, error: membershipError } = await supabase
    .from("memberships")
    .select("tenant_id, role")
    .eq("user_id", user.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (membershipError || !membership) return { error: "No active company membership was found." };
  if (!["company_admin", "hr_admin"].includes(membership.role)) return { error: "You do not have permission to add employees." };

  const value = parsed.data;
  const { error } = await supabase.from("employees").insert({
    tenant_id: membership.tenant_id,
    employee_code: value.employee_code,
    first_name: value.first_name,
    last_name: value.last_name,
    work_email: value.work_email || null,
    joining_date: value.joining_date || null,
    employment_status: "active"
  });

  if (error) {
    if (error.code === "23505") return { error: "That employee ID or email is already in use in this company." };
    return { error: "Could not save employee. Verify the details and try again." };
  }

  revalidatePath("/employees");
  revalidatePath("/dashboard");
  return { success: "Employee added successfully." };
}
