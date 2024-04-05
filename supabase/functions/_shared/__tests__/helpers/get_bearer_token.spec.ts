import getBearerToken from "../../helpers/get_bearer_token.ts";
import * as mf from "https://deno.land/x/mock_fetch@0.3.0/mod.ts";

import { assertEquals } from "https://deno.land/std@0.215.0/assert/mod.ts";

Deno.test("getBearerToken returns a bearer token", async () => {
  // Arrange
  mf.install();

  mf.mock("POST@/dineroapi/oauth/token", (_req) => {
    return new Response(
      JSON.stringify({
        access_token: "value",
        expires_in: 3600,
        refresh_token: "",
        token_type: "Bearer",
      }),
      {
        status: 200,
      },
    );
  });

  // Act
  const res = await getBearerToken();

  // Assert

  assertEquals(res, {
    access_token: "value",
    expires_in: 3600,
    refresh_token: "",
    token_type: "Bearer",
  });
});
