import { latestReleaseURL } from '../release';
import React from 'react';
import { ArrowRight, ArrowDown, ChevronRight } from 'lucide-react';
import { AppleLogo } from './Navbar';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface HeroProps {
  lang: Language;
}

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  return (
    <section className="pt-14 pb-10 sm:pt-20 sm:pb-12 text-center">
      <div className="container-page flex flex-col items-center">
        {/* Shoji release announcement pill */}
        <a
          href={latestReleaseURL}
          target="_blank"
          rel="noopener noreferrer"
          className="shoji-badge mb-7 group"
        >
          <span className="shoji-badge-new">{t.badgeNew}</span>
          <span className="truncate max-w-[240px] sm:max-w-none">{t.badgeText}</span>
          <ChevronRight
            className="w-3.5 h-3.5 text-[var(--color-ink-3)] transition-transform group-hover:translate-x-0.5 shrink-0"
            strokeWidth={2}
          />
        </a>

        {/* Shoji signature Display Headline with tilted inline 3D chips */}
        <h1 className="display text-[clamp(40px,6.2vw,76px)] text-[var(--color-ink)] max-w-[15ch] sm:max-w-none">
          <span>{t.titleLead}</span>{' '}
          <span className="hchip hchip-menu" aria-hidden="true">
            <svg viewBox="0 0 64 40" className="w-full h-full rounded-[0.18em] overflow-hidden">
              <rect width="64" height="40" fill="#dbeafe" />
              <rect x="4" y="4" width="26" height="32" rx="4" fill="#0a7cff" />
              <rect x="34" y="4" width="26" height="14" rx="3.5" fill="#93c5fd" />
              <rect x="34" y="22" width="26" height="14" rx="3.5" fill="#bfdbfe" />
            </svg>
          </span>{' '}
          <span className="text-[var(--color-ink-3)]">{t.titleMuted}</span>
          <br />
          <span className="hchip hchip-mark" aria-hidden="true">
            <svg viewBox="0 0 40 40" className="w-[74%] h-[74%] text-[var(--color-ink)]" fill="none">
              <rect x="4" y="5" width="32" height="30" rx="8" fill="currentColor" />
              <path
                d="M16.2 15.5L11.8 20L16.2 24.5M23.8 15.5L28.2 20L23.8 24.5M21.2 14.2L18.8 25.8"
                stroke="var(--color-surface)"
                strokeWidth="2.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>{' '}
          <span>{t.titleEnd}</span>
        </h1>

        {/* Lede */}
        <p className="mt-6 max-w-[35rem] text-balance text-[17px] sm:text-[18.5px] leading-[1.55] text-[var(--color-ink-2)]">
          {t.lede}
        </p>

        {/* Shoji Pill CTA Row */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary"
          >
            <AppleLogo className="w-4 h-4 -mt-0.5 shrink-0" />
            <span>{t.ctaPrimary}</span>
            <span className="btn-dot" aria-hidden="true">
              <ArrowRight className="w-4 h-4" strokeWidth={2.2} />
            </span>
          </a>

          <a href="#demo" className="btn-ghost">
            <span>{t.ctaTry}</span>
            <ArrowDown className="w-4 h-4 text-[var(--color-ink-3)]" strokeWidth={2} />
          </a>

          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="btn-ghost"
          >
            <GithubIcon className="w-4 h-4 text-[var(--color-ink-2)]" />
            <span>{t.ctaGithub}</span>
          </a>
        </div>

        {/* Meta strip with soft accent pill */}
        <div className="mt-5 inline-flex flex-wrap items-center justify-center gap-x-2.5 gap-y-1.5 text-[13.5px] text-[var(--color-ink-3)]">
          <span>{t.metaLeft}</span>
          <span aria-hidden="true">·</span>
          <span>{t.metaMid}</span>
          <span aria-hidden="true">·</span>
          <span className="sale-tag">{t.metaTag}</span>
        </div>
      </div>
    </section>
  );
};
