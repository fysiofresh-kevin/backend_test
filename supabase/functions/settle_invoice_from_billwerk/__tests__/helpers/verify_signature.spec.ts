import { assertEquals } from "https://deno.land/std@0.213.0/assert/assert_equals.ts";
import verify_signature from "../../helpers/verify_signature.ts";

const test_false_signature = () => {
  // Arrange
  const signature =
    "797b4ddc7fb961637164320f7f19ec0a51bf661c5ef7e79474f37dc417dd32dd";
  const timestamp = "2024-02-05T08:57:01.267Z";
  const id = "1234";

  // Act
  const result = verify_signature(timestamp, id, signature);

  // Assert
  assertEquals(result, false);
};

const test_true_signature = () => {
  // Arrange
  const signature =
    "797b4ddc7fb961637164320f7f19ec0a51bf661c5ef7e79474f37dc417dd32dd";
  const timestamp = "2024-02-05T08:57:01.267Z";
  const id = "4f20695bd2bfbf89a14840d084b7360e";

  // Act
  const result = verify_signature(timestamp, id, signature);

  // Assert
  assertEquals(result, true);
};

Deno.test("should confirm billwerk false signature", test_false_signature);
Deno.test("should confirm billwerk true signature", test_true_signature);
