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

const FoldChip: React.FC = () => (
  <span className="hchip hchip-fold">
    <span className="relative block h-full w-full overflow-hidden rounded-[0.2em] bg-[linear-gradient(160deg,#dfe7ff,#f3dff0_60%,#ffe9d6)] dark:bg-[linear-gradient(160deg,#1d2547,#33203d_60%,#3a2a24)]">
      <span
        className="absolute block rounded-[0.07em] shadow-[0_0.02em_0.06em_rgba(0,0,0,0.25)]"
        style={{ background: 'var(--color-accent)', left: '3.2%', top: '5%', width: '45.5%', height: '90%' }}
      />
      <span
        className="absolute block rounded-[0.07em] shadow-[0_0.02em_0.06em_rgba(0,0,0,0.25)]"
        style={{ background: 'color-mix(in srgb, var(--color-accent) 55%, white)', left: '52%', top: '5%', width: '45%', height: '43%' }}
      />
      <span
        className="absolute block rounded-[0.07em] shadow-[0_0.02em_0.06em_rgba(0,0,0,0.25)]"
        style={{ background: 'color-mix(in srgb, var(--color-accent) 35%, white)', left: '52%', top: '53%', width: '45%', height: '42%' }}
      />
    </span>
  </span>
);

const MarkChip: React.FC = () => (
  <span className="hchip hchip-mark">
    <span className="flex h-full w-full items-center justify-center rounded-[0.2em] bg-[linear-gradient(180deg,#ffffff,#eeeef2)] text-[#141418] dark:bg-[linear-gradient(180deg,#2c2c33,#1c1c21)] dark:text-white">
      <svg viewBox="-12 -12 80 76" className="h-[62%] w-auto overflow-visible" aria-hidden="true">
        <path
          d="M13,0 H32.5 A1.5,1.5 0 0 1 34,1.5 V17 A7,7 0 0 1 27,24 H1.5 A1.5,1.5 0 0 1 0,22.5 V13 A13,13 0 0 1 13,0 Z"
          fill="currentColor"
        />
        <path
          d="M39.5,0 H43 A13,13 0 0 1 56,13 V22.5 A1.5,1.5 0 0 1 54.5,24 H45 A7,7 0 0 1 38,17 V1.5 A1.5,1.5 0 0 1 39.5,0 Z"
          fill="currentColor"
        />
        <path
          d="M1.5,28 H27 A7,7 0 0 1 34,35 V50.5 A1.5,1.5 0 0 1 32.5,52 H13 A13,13 0 0 1 0,39 V29.5 A1.5,1.5 0 0 1 1.5,28 Z"
          fill="currentColor"
        />
        <path
          d="M45,28 H54.5 A1.5,1.5 0 0 1 56,29.5 V39 A13,13 0 0 1 43,52 H39.5 A1.5,1.5 0 0 1 38,50.5 V35 A7,7 0 0 1 45,28 Z"
          fill="currentColor"
        />
      </svg>
    </span>
  </span>
);

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  return (
    <section className="pt-14 sm:pt-20 text-center">
      <div className="container-page flex flex-col items-center">
        {/* Shoji release announcement pill */}
        <a
          href={latestReleaseURL}
          target="_blank"
          rel="noopener noreferrer"
          className="shoji-badge group"
        >
          <span className="shoji-badge-new">{t.badgeNew}</span>
          <span className="truncate max-w-[240px] sm:max-w-none">{t.badgeText}</span>
          <ChevronRight
            className="w-3.5 h-3.5 text-[var(--color-ink-3)] transition-transform group-hover:translate-x-0.5 shrink-0"
            strokeWidth={2}
          />
        </a>

        {/* Optically centered Shoji Display Headline with tilted inline 3D chips */}
        <h1
          className="display mt-6 text-[clamp(40px,min(6.2vw,9.4vh),86px)] text-[var(--color-ink)] text-center"
          aria-label={
            lang === 'zh'
              ? '你的访达，右键动作，随手脚本化。'
              : 'Your Finder, right-click scripted.'
          }
        >
          <span aria-hidden="true" className="inline-block">
            {lang === 'zh' ? (
              <>
                <span className="inline-flex items-baseline justify-center -translate-x-[0.06em]">
                  <span>你的访达</span>
                  <span className="inline-block w-[0.52em] text-left">，</span>
                  <FoldChip />
                  <span className="text-[var(--color-ink-3)] ml-[0.08em]">右键动作</span>
                </span>
                <br />
                <span className="inline-flex items-baseline justify-center -translate-x-[0.08em] mt-[0.04em]">
                  <MarkChip />
                  <span className="ml-[0.1em]">随手脚本化</span>
                  <span className="inline-block w-[0.42em] text-left">。</span>
                </span>
              </>
            ) : (
              <>
                <span className="inline-flex items-baseline justify-center">
                  <span>Your Finder,</span>{' '}
                  <FoldChip />{' '}
                  <span className="text-[var(--color-ink-3)]">right-click</span>
                </span>
                <br />
                <span className="inline-flex items-baseline justify-center -translate-x-[0.06em]">
                  <MarkChip />{' '}
                  <span>scripted.</span>
                </span>
              </>
            )}
          </span>
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
