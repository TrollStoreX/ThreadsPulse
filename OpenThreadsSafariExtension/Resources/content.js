
(() => {
    "use strict";

    // Prevent duplicate initialization
    if (window.__openThreadsInitialized) return;
    window.__openThreadsInitialized = true;

    let attemptedUrl = null;
    let redirecting = false;

    // Check Threads domains
    function isThreadsHost(hostname) {
        const host = hostname.toLowerCase();

        return (
            host === "threads.com" ||
            host.endsWith(".threads.com") ||
            host === "threads.net" ||
            host.endsWith(".threads.net")
        );
    }

    // Normalize Threads URL
    function canonicalThreadsUrl(locationUrl) {
        try {
            const url = new URL(locationUrl);

            if (!isThreadsHost(url.hostname)) {
                return null;
            }

            url.protocol = "https:";
            url.hostname = "www.threads.com";

            [
                "utm_source",
                "utm_medium",
                "utm_campaign",
                "utm_content",
                "utm_term",
                "igshid"
            ].forEach(key => {
                url.searchParams.delete(key);
            });

            return url;
        } catch (error) {
            console.error(
                "Open Threads: Invalid URL",
                error
            );

            return null;
        }
    }

    // Extract post shortcode
    function getPostShortcode(url) {
        const segments = url.pathname
            .split("/")
            .filter(Boolean);

        // /@username/post/POST_ID
        const postIndex = segments.indexOf("post");

        if (
            postIndex >= 0 &&
            segments[postIndex + 1]
        ) {
            return segments[postIndex + 1];
        }

        // /t/POST_ID
        if (
            segments[0] === "t" &&
            segments[1]
        ) {
            return segments[1];
        }

        return null;
    }

    // Extract username
    function getUsername(url) {
        const segments = url.pathname
            .split("/")
            .filter(Boolean);

        // /@username
        if (
            segments.length === 1 &&
            segments[0].startsWith("@")
        ) {
            const username = segments[0].slice(1);

            return username || null;
        }

        return null;
    }

    // Build native Threads URL
    function buildAppUrl(url) {
        const shortcode = getPostShortcode(url);

        // Open specific post
        if (shortcode) {
            return (
                "barcelona://media?shortcode=" +
                encodeURIComponent(shortcode)
            );
        }

        const username = getUsername(url);

        // Open specific user profile
        if (username) {
            return (
                "barcelona://user?username=" +
                encodeURIComponent(username)
            );
        }

        // Fallback for other Threads URLs
        const webUrl = url.toString();
        const encoded = encodeURIComponent(webUrl);

        return (
            "barcelona://inter_app_redirect?url=" +
            encoded +
            "&target_url=" +
            encoded +
            "&web_url=" +
            encoded
        );
    }

    // Open Threads App
    function openInThreads() {
        if (redirecting) return;

        const url = canonicalThreadsUrl(
            window.location.href
        );

        if (!url) return;

        const webUrl = url.toString();

        // Prevent duplicate redirects
        if (attemptedUrl === webUrl) return;

        const appUrl = buildAppUrl(url);

        attemptedUrl = webUrl;
        redirecting = true;

        console.log(
            "Open Threads:",
            webUrl,
            appUrl
        );

        // Launch native Threads app
        window.location.href = appUrl;
    }

    // Handle SPA navigation
    function handleNavigation() {
        const url = canonicalThreadsUrl(
            window.location.href
        );

        if (!url) return;

        const webUrl = url.toString();

        if (attemptedUrl === webUrl) return;

        redirecting = false;
        openInThreads();
    }

    // Initial execution
    openInThreads();

    // Monitor pushState
    const originalPushState = history.pushState;

    history.pushState = function (...args) {
        const result = originalPushState.apply(
            this,
            args
        );

        setTimeout(handleNavigation, 0);

        return result;
    };

    // Monitor replaceState
    const originalReplaceState = history.replaceState;

    history.replaceState = function (...args) {
        const result = originalReplaceState.apply(
            this,
            args
        );

        setTimeout(handleNavigation, 0);

        return result;
    };

    // Browser back / forward
    window.addEventListener("popstate", () => {
        setTimeout(handleNavigation, 0);
    });

    // Page restored from browser cache
    window.addEventListener("pageshow", () => {
        setTimeout(handleNavigation, 0);
    });

})();
