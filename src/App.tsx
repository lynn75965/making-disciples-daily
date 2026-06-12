import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ROUTES } from './constants/routes';
import { BRANDING } from './config/branding';
import { audienceTerm, type ParticipantRole } from './constants/audienceConfig';

// Making Disciples Daily -- App shell (Phase 0 governance scaffold).
//
// RULE #3: every path in src/constants/routes.ts is wired here in the SAME pass.
// Phase 0 ships only ROUTES.HOME. Feature routes are added in their phase, each
// time updating BOTH routes.ts and this file together.
//
// RULE #13: participant-facing labels below resolve through audienceConfig.ts.
// No participant string ("discipler", "disciple", ...) is hardcoded here.

const AUDIENCE_PREVIEW: readonly ParticipantRole[] = [
  'discipler',
  'disciple',
  'apprentice',
  'groupMember',
];

function Landing() {
  return (
    <main className="min-h-screen bg-slate-50 text-slate-900">
      <div className="mx-auto max-w-2xl px-6 py-16">
        <h1 className="text-3xl font-bold tracking-tight">
          {BRANDING.appName}
        </h1>
        <p className="mt-3 text-lg text-slate-600">{BRANDING.tagline}</p>

        <section aria-labelledby="scaffold-status" className="mt-10">
          <h2 id="scaffold-status" className="text-sm font-semibold uppercase tracking-wide text-slate-500">
            Phase 0 scaffold
          </h2>
          <p className="mt-2 text-slate-700">
            Governance and SSOT skeleton are in place. No features yet.
          </p>
        </section>

        <section aria-labelledby="audience-terms" className="mt-8">
          <h2 id="audience-terms" className="text-sm font-semibold uppercase tracking-wide text-slate-500">
            Audience terms (resolved via SSOT)
          </h2>
          <ul className="mt-2 flex flex-wrap gap-2">
            {AUDIENCE_PREVIEW.map((role) => (
              <li
                key={role}
                className="rounded-full bg-white px-3 py-1 text-sm text-slate-700 ring-1 ring-slate-200"
              >
                {audienceTerm(role)}
              </li>
            ))}
          </ul>
        </section>
      </div>
    </main>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path={ROUTES.HOME} element={<Landing />} />
      </Routes>
    </BrowserRouter>
  );
}
