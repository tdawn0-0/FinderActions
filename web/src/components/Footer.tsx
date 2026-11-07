import { latestReleaseURL } from '../release';
import React from 'react';
import { ArrowRight } from 'lucide-react';
import { AppleLogo, ShojiMark } from './Navbar';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FooterProps {
  lang: Language;
}

export const Footer: React.FC<FooterProps> = ({ lang }) => {
  const closing = translations[lang].closing;
  const t = translations[lang].footer;


  return (
    <footer className="pt-16 sm:pt-24">
      {/* Shoji Closing CTA Callout */}
      <div className="container-page pb-20 sm:pb-28 flex flex-col items-center text-center">
        <div className="w-14 h-14 rounded-[16px] bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line),0_12px_28px_-10px_rgba(15,23,42,0.18)] flex items-center justify-center mb-6">
          <ShojiMark className="w-8 h-8 text-[var(--color-ink)]" />
        </div>

        <h2 className="display text-balance text-[clamp(32px,4.2vw,54px)] text-[var(--color-ink)]">
          {closing.titleDark}
        </h2>

        <p className="mt-4 max-w-[32rem] text-balance text-[16.5px] leading-relaxed text-[var(--color-ink-2)]">
          {closing.sub}
        </p>

        <div className="mt-7">
          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary"
          >
            <AppleLogo className="w-4 h-4 -mt-0.5 shrink-0" />
            <span>{closing.cta}</span>
            <span className="btn-dot" aria-hidden="true">
              <ArrowRight className="w-4 h-4" strokeWidth={2.2} />
            </span>
          </a>
        </div>

        <p className="mt-4 text-[13px] text-[var(--color-ink-3)]">
          {closing.meta}
        </p>
      </div>

      {/* Bottom Bar */}
      <div className="border-t border-[var(--color-line)] py-8">
        <div className="container-page flex flex-col sm:flex-row items-center justify-between gap-4 text-[13.5px] text-[var(--color-ink-3)]">
          <div className="flex items-center gap-2.5">
            <ShojiMark className="w-[18px] h-[18px] text-[var(--color-ink)]" />
            <span className="font-semibold text-[var(--color-ink)]">FinderActions</span>
            <span>·</span>
            <span>MIT License</span>
          </div>

          <div className="flex items-center gap-6">
            <a href="#guide" className="hover:text-[var(--color-ink)] transition-colors">
              {t.docs}
            </a>
            <a
              href="https://github.com/tdawn0-0/FinderActions"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-[var(--color-ink)] transition-colors"
            >
              {t.github}
            </a>
            <a
              href={latestReleaseURL}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-[var(--color-ink)] transition-colors"
            >
              {t.releases}
            </a>
            <button
              type="button"
              onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
              className="hover:text-[var(--color-ink)] transition-colors cursor-pointer"
            >
              {t.backToTop}
            </button>
          </div>
        </div>
      </div>
    </footer>
  );
};
