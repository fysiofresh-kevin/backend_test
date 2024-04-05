import CryptoJS from "npm:crypto-js";
import { WEBHOOK_SECRET } from "../../_shared/environment.ts";
const verify_signature = (
  timestamp: Date | string,
  id: string,
  signature: string,
): boolean => {
  const secret = WEBHOOK_SECRET;

  if (!secret) {
    throw new Error("WEBHOOK_SECRET is not defined");
  }

  const generatedSignature = CryptoJS.HmacSHA256(
    `${timestamp.toString()}${id}`,
    secret,
  )
    .toString();

  return signature === generatedSignature;
};

export default verify_signature;
