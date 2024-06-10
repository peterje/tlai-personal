/**
 * By default, Remix will handle hydrating your app on the client for you.
 * You are free to delete this file if you'd like to, but if you ever want it revealed again, you can run `npx remix reveal` ✨
 * For more information, see https://remix.run/file-conventions/entry.client
 */

import { RemixBrowser } from "@remix-run/react";
import posthog from "posthog-js";
import { StrictMode, startTransition, useEffect } from "react";
import { hydrateRoot } from "react-dom/client";

function PosthogInit() {
  useEffect(() => {
    posthog.init("phc_5wuhGkyKhi2oCluxb63Gqki9bveFwl6CaZE2iDXfn6p", {
      api_host: "https://us.posthog.com",
    });
  }, []);

  return null;
}

startTransition(() => {
  hydrateRoot(
    document,
    <StrictMode>
      <RemixBrowser />
      <PosthogInit />
    </StrictMode>,
  );
});
