<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="refresh" content="60" />
    <title>{{APP_NAME}} — Under maintenance</title>
    <link rel="icon" href="./logo.png" type="image/png" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap"
      rel="stylesheet"
    />
    <style>
      :root {
        --primary: {{PRIMARY_COLOR:-#6d5dfb}};
        --primary-dark: {{PRIMARY_COLOR_DARK:-#5548c9}};
        --text: #111827;
        --muted: #6b7280;
        --card: #ffffff;
        --radius: 0.75rem;
      }

      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }

      body {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        font-family:
          "Inter",
          system-ui,
          -apple-system,
          "Segoe UI",
          Roboto,
          sans-serif;
        background-color: #f5f4ff;
        background-image:
          radial-gradient(
            ellipse 80% 60% at 50% -10%,
            rgba(109, 93, 251, 0.18),
            transparent
          ),
          radial-gradient(
            ellipse 60% 50% at 100% 100%,
            rgba(91, 79, 212, 0.1),
            transparent
          ),
          linear-gradient(
            135deg,
            rgba(109, 93, 251, 0.06) 0%,
            rgba(245, 244, 255, 1) 40%,
            rgba(109, 93, 251, 0.04) 100%
          );
        color: var(--text);
        padding: 1.5rem;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
      }

      .card {
        max-width: 26rem;
        width: 100%;
        text-align: center;
        background: var(--card);
        border-radius: 1rem;
        padding: 2.75rem 2rem 2.5rem;
        border: 1px solid rgba(109, 93, 251, 0.12);
        box-shadow:
          0 1px 2px rgb(0 0 0 / 0.04),
          0 8px 32px rgb(109 93 251 / 0.14);
        animation: fade-up 0.5s ease-out both;
      }

      .brand {
        display: flex;
        flex-direction: column;
        align-items: center;
        margin-bottom: 1.5rem;
      }

      .badge {
        display: inline-flex;
        align-items: center;
        gap: 0.375rem;
        margin-top: 1rem;
        padding: 0.3125rem 0.75rem;
        font-size: 0.75rem;
        font-weight: 500;
        letter-spacing: 0.02em;
        text-transform: uppercase;
        color: var(--primary-dark);
        background: rgba(109, 93, 251, 0.1);
        border-radius: 9999px;
      }

      .badge::before {
        content: "";
        width: 0.4375rem;
        height: 0.4375rem;
        border-radius: 50%;
        background: var(--primary);
        animation: pulse 2s ease-in-out infinite;
      }

      .logo {
        display: block;
        width: 4.5rem;
        height: 4.5rem;
        object-fit: contain;
      }

      h1 {
        font-size: 1.5rem;
        font-weight: 600;
        letter-spacing: -0.02em;
        margin-bottom: 0.625rem;
      }

      .lead {
        color: var(--muted);
        line-height: 1.65;
        font-size: 0.9375rem;
        max-width: 22rem;
        margin: 0 auto;
      }

      .spinner {
        width: 2.25rem;
        height: 2.25rem;
        margin: 2rem auto 0;
        border: 2.5px solid rgba(109, 93, 251, 0.18);
        border-top-color: var(--primary);
        border-radius: 50%;
        animation: spin 0.85s linear infinite;
      }

      .footer {
        margin-top: 1.5rem;
        font-size: 0.8125rem;
        color: var(--muted);
        line-height: 1.5;
      }

      .countdown {
        margin-top: 0.75rem;
        font-size: 0.75rem;
        color: rgba(107, 114, 128, 0.85);
        font-variant-numeric: tabular-nums;
      }

      @keyframes spin {
        to {
          transform: rotate(360deg);
        }
      }

      @keyframes fade-up {
        from {
          opacity: 0;
          transform: translateY(0.75rem);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }

      @keyframes pulse {
        0%,
        100% {
          opacity: 1;
        }
        50% {
          opacity: 0.4;
        }
      }

      @media (prefers-reduced-motion: reduce) {
        .card {
          animation: none;
        }

        .spinner {
          animation: none;
          border-top-color: rgba(109, 93, 251, 0.5);
        }

        .badge::before {
          animation: none;
        }
      }
    </style>
  </head>
  <body>
    <main class="card">
      <div class="brand">
        <img class="logo" src="./logo.png" alt="{{APP_NAME}}" width="72" height="72" />
        <span class="badge">Maintenance</span>
      </div>
      <h1>We&rsquo;ll be right back</h1>
      <p class="lead">
        Sorry for the inconvenience &mdash; we&rsquo;re performing maintenance to
        improve your experience. This page will refresh automatically.
      </p>
      <div class="spinner" role="status" aria-label="Loading"></div>
      <p class="footer">Thank you for your patience.</p>
      <p class="countdown" aria-live="polite">
        Checking again in <span id="countdown">60</span>s
      </p>
    </main>
    <script>
      (function () {
        var seconds = 60;
        var el = document.getElementById("countdown");
        if (!el || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
          return;
        }
        setInterval(function () {
          seconds -= 1;
          if (seconds < 1) seconds = 60;
          el.textContent = String(seconds);
        }, 1000);
      })();
    </script>
  </body>
</html>
