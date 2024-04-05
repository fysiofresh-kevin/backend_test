import {DINERO_CLIENT_ID, DINERO_SECRET, DINERO_API_KEY, TRANSFER_PROTOCOL, AUTH_DINERO_URL} from "../../_shared/environment.ts";
interface IDineroBearerResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  refresh_token: string;
}

const getBearerToken = async (): Promise<IDineroBearerResponse> => {
  const dineroApiKey = DINERO_API_KEY;
  const params = new URLSearchParams();
  params.append("grant_type", "password");
  params.append("scope", "read write");
  params.append("username", dineroApiKey);
  params.append("password", dineroApiKey);

  const encodedCredentials = btoa(
    `${DINERO_CLIENT_ID}:${DINERO_SECRET}`,
  ).toString();

  const headers = new Headers({
    "Content-Type": "application/x-www-form-urlencoded",
    "Authorization": `Basic ${encodedCredentials}`,
  });

  const res = await fetch(
    `${TRANSFER_PROTOCOL}${AUTH_DINERO_URL}/dineroapi/oauth/token`,
    {
      headers,
      body: params,
      method: "POST",
    },
  );

  const data = await res.json();

  return data;
};

export default getBearerToken;
