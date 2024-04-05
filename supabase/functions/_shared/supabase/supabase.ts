import { createClient } from "https://esm.sh/@supabase/supabase-js";
import {TRANSFER_PROTOCOL, SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY} from "../environment.ts";
const url = `${TRANSFER_PROTOCOL}${SUPABASE_URL}`;
const anon_key = SUPABASE_ANON_KEY;
const service_role_key = SUPABASE_SERVICE_ROLE_KEY;

export const supabase = createClient(
  url,
  anon_key,
);

export const supabaseServiceClient = createClient(
  url,
  service_role_key,
);

export const createSupabaseClientWithAuthHeader = (authHeader: string) => {
  return createClient(
    url,
    anon_key,
    { global: { headers: { Authorization: authHeader } } },
  );
};

export const clientCreation = {
  createSupabaseClientWithAuthHeader,
};
