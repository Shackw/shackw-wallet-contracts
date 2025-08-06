import { isAddress } from "ethers";
import * as v from "valibot";

const ethereumAddressValidator = v.custom<string>(
  (value): value is string => typeof value === "string" && isAddress(value),
  () => "Invalid Ethereum address",
);

const privateKeyValidator = v.custom<string>(
  (value): value is string =>
    typeof value === "string" && /^0x[0-9a-fA-F]{64}$/.test(value),
  () => "Invalid Ethereum private key",
);

export const EnvironmentSchema = v.object({
  JPYC_TOKEN_ADDRESS: v.pipe(v.string(), ethereumAddressValidator),
  USDC_TOKEN_ADDRESS: v.pipe(v.string(), ethereumAddressValidator),
  EURC_TOKEN_ADDRESS: v.pipe(v.string(), ethereumAddressValidator),
  JPYC_TRUSTED_SIGNER: v.pipe(v.string(), privateKeyValidator),
  USDC_TRUSTED_SIGNER: v.pipe(v.string(), privateKeyValidator),
  EURC_TRUSTED_SIGNER: v.pipe(v.string(), privateKeyValidator),
});

export type EnvironmentModel = v.InferOutput<typeof EnvironmentSchema>;
