import { latestReleaseURL } from '../release';
import React, { useState } from 'react';
import { Check, Copy, ArrowUpRight, ChevronDown } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface GettingStartedProps {
  lang: Language;
}

export const GettingStarted: React.FC<GettingStartedProps> = ({ lang }) => {
  const t = translations[lang].guide;
  const [copied, setCopied] = useState(false);

  const troubleCmd = `pluginkit -a "/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
pluginkit -e use -i com.finderactions.host.FinderSync
killall Finder`;

  const handleCopyTrouble = () => {
    navigator.clipboard.writeText(troubleCmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  return (
    <section id="guide" className="scroll-mt-16 py-20 sm:py-28">
      <div className="container-page">
        <div className="flex flex-col items-center text-center gap-3 mb-12 sm:mb-14">
          <p className="eyebrow">{t.eyebrow}</p>
          <h2 className="display text-[clamp(30px,3.6vw,48px)] text-[var(--color-ink)]">
            {t.titleDark}{' '}
            <span className="text-[var(--color-ink-3)]">{t.titleMuted}</span>
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-6">
          {t.steps.map((step, idx) => (
            <div
              key={step.num}
              className="rounded-[26px] bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line)] p-7 flex flex-col justify-between gap-5"
            >
              <div>
                <span className="sale-tag inline-block mb-4">{step.num}</span>
                <h3 className="text-[18px] font-semibold tracking-tight text-[var(--color-ink)] mb-2">
                  {step.title}
                </h3>
                <p className="text-[15px] leading-[1.55] text-[var(--color-ink-2)]">
                  {step.desc}
                </p>
              </div>

              {idx === 0 && (
                <a
                  href={latestReleaseURL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 text-[14px] font-semibold text-[var(--color-accent)] hover:underline w-fit"
                >
                  <span>{t.downloadLink}</span>
                  <ArrowUpRight className="w-4 h-4" />
                </a>
              )}
            </div>
          ))}
        </div>

        <details className="rounded-[22px] bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line)] group">
          <summary className="px-6 py-4 text-[14.5px] font-medium text-[var(--color-ink-2)] hover:text-[var(--color-ink)] cursor-pointer select-none flex items-center justify-between gap-4 list-none">
            <span>{t.troubleSummary}</span>
            <ChevronDown className="w-4 h-4 text-[var(--color-ink-3)] transition-transform group-open:rotate-180 shrink-0" />
          </summary>

          <div className="px-6 pb-6 pt-1">
            <div className="relative rounded-[16px] bg-[#121317] text-[#f5f5f7] p-4 font-mono text-[12.5px] leading-[1.7] overflow-x-auto">
              <button
                type="button"
                onClick={handleCopyTrouble}
                className="absolute top-3 right-3 h-7 px-3 rounded-full bg-white/10 hover:bg-white/15 text-[12px] font-sans font-medium text-white inline-flex items-center gap-1.5 cursor-pointer"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-[#4cc38a]" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copied ? t.copiedCmd : t.copyCmd}</span>
              </button>
              <pre>
                <code>{troubleCmd}</code>
              </pre>
            </div>
          </div>
        </details>
      </div>
    </section>
  );
};
