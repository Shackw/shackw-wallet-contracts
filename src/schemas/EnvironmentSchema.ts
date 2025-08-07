import { isAddress } from "ethers";
import * as v from "valibot";

const ethereumAddressValidator = v.custom<string>(
  (value): value is string => typeof value === "string" && isAddress(value),
  () => "Invalid Ethereum address",
);

export const EnvironmentSchema = v.object({
  JPYC_TOKEN_ADDRESS: v.pipe(v.string(), ethereumAddressValidator),
  USDC_TOKEN_ADDRESS: v.pipe(v.string(), ethereumAddressValidator),
  EURC_TOKEN_ADDRESS: v.pipe(v.string(), ethereumAddressValidator),
  JPYC_TRUSTED_SIGNER: v.pipe(v.string(), ethereumAddressValidator),
  USDC_TRUSTED_SIGNER: v.pipe(v.string(), ethereumAddressValidator),
  EURC_TRUSTED_SIGNER: v.pipe(v.string(), ethereumAddressValidator),
});

export type EnvironmentModel = v.InferOutput<typeof EnvironmentSchema>;
