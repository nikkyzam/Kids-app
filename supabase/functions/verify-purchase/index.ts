// Entry point for the verify-purchase edge function.
//
// The logic lives in verify.ts so it can be exercised by verify_test.ts
// without starting a server; this file is only the wiring.

import { handleRequest } from "./verify.ts";

Deno.serve(handleRequest);
