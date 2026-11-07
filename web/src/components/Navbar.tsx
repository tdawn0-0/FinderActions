import { latestReleaseURL } from '../release';
import React, { useState } from 'react';
import { Moon, Sun, Menu, X } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface NavbarProps {
  lang: Language;
  dark: boolean;
  onToggleLang: () => void;
  onToggleTheme: () => void;
}

export const ShojiMark: React.FC<{ className?: string }> = ({ className = 'w-5 h-5' }) => (
  <svg
    viewBox="0 0 24 24"
    fill="none"
    aria-hidden="true"
    className={`shrink-0 ${className}`}
  >
    <rect x="2" y="3" width="20" height="18" rx="5.5" fill="currentColor" />
    <path
      d="M9.5 9.25L6.75 12L9.5 14.75M14.5 9.25L17.25 12L14.5 14.75M12.75 8.5L11.25 15.5"
      stroke="var(--color-paper)"
      strokeWidth="1.9"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

export const AppleLogo: React.FC<{ className?: string }> = ({ className = 'w-3.5 h-3.5' }) => (
  <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" className={className}>
    <path d="M11.182.008C11.148-.03 9.923.023 8.857 1.18c-1.066 1.156-.902 2.482-.878 2.516s1.52.087 2.475-1.258.762-2.391.728-2.43m3.314 11.733c-.048-.096-2.325-1.234-2.113-3.422s1.675-2.789 1.698-2.854-.597-.79-1.254-1.157a3.7 3.7 0 0 0-1.563-.434c-.108-.003-.483-.095-1.254.116-.508.139-1.653.589-1.968.607-.316.018-1.256-.522-2.267-.665-.647-.125-1.333.131-1.824.328-.49.196-1.422.754-2.074 2.237-.652 1.482-.311 3.83-.067 4.56s.625 1.924 1.273 2.796c.576.984 1.34 1.667 1.659 1.899s1.219.386 1.843.067c.502-.308 1.408-.485 1.766-.472.357.013 1.061.154 1.782.539.571.197 1.111.115 1.652-.105.541-.221 1.324-1.059 2.238-2.758q.52-1.185.473-1.282" />
  </svg>
);

export const Navbar: React.FC<NavbarProps> = ({
  lang,
  dark,
  onToggleLang,
  onToggleTheme,
}) => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const t = translations[lang].nav;

  const links = [
    { label: t.how, href: '#how' },
    { label: t.features, href: '#features' },
    { label: t.compare, href: '#compare' },
    { label: t.guide, href: '#guide' },
    { label: t.faq, href: '#faq' },
  ];

  return (
    <header className="sticky top-0 z-50 w-full backdrop-blur-md bg-[var(--color-paper)]/82 border-b border-[var(--color-line)]">
      <div className="container-page h-16 flex items-center justify-between gap-4">
        <a
          href="#"
          className="flex items-center gap-2.5 text-[16px] font-semibold tracking-tight text-[var(--color-ink)] shrink-0"
        >
          <ShojiMark className="w-[22px] h-[22px]" />
          <span>FinderActions</span>
        </a>

        <nav className="hidden md:flex items-center gap-7">
          {links.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="text-[14.5px] text-[var(--color-ink-2)] hover:text-[var(--color-ink)] transition-colors"
            >
              {item.label}
            </a>
          ))}
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="text-[14.5px] text-[var(--color-ink-2)] hover:text-[var(--color-ink)] transition-colors"
          >
            {t.github}
          </a>
        </nav>

        <div className="flex items-center gap-2.5 shrink-0">
          <button
            type="button"
            onClick={onToggleLang}
            aria-label="Switch language"
            className="h-9 px-2.5 rounded-full text-[13px] font-medium text-[var(--color-ink-2)] hover:text-[var(--color-ink)] hover:bg-[var(--color-surface)] transition-colors cursor-pointer"
          >
            {lang === 'en' ? '中文' : 'EN'}
          </button>

          <button
            type="button"
            onClick={onToggleTheme}
            aria-label="Toggle theme"
            className="h-9 w-9 rounded-full inline-flex items-center justify-center text-[var(--color-ink-2)] hover:text-[var(--color-ink)] hover:bg-[var(--color-surface)] transition-colors cursor-pointer"
          >
            {dark ? <Sun className="w-4 h-4" strokeWidth={1.8} /> : <Moon className="w-4 h-4" strokeWidth={1.8} />}
          </button>

          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:inline-flex items-center gap-2 h-9 px-4 rounded-full bg-[var(--color-ink)] text-[var(--color-paper)] text-[13.5px] font-semibold hover:opacity-90 transition-opacity"
          >
            <AppleLogo className="w-3.5 h-3.5 -mt-0.5" />
            <span>{t.download}</span>
          </a>

          <button
            type="button"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Toggle menu"
            aria-expanded={mobileOpen}
            className="md:hidden h-9 w-9 rounded-full inline-flex items-center justify-center text-[var(--color-ink-2)] hover:text-[var(--color-ink)] cursor-pointer"
          >
            {mobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {mobileOpen && (
        <div className="md:hidden px-6 pb-5 pt-2 bg-[var(--color-paper)] border-b border-[var(--color-line)] flex flex-col gap-1">
          {links.map((item) => (
            <a
              key={item.href}
              href={item.href}
              onClick={() => setMobileOpen(false)}
              className="py-2 text-[15px] text-[var(--color-ink-2)] hover:text-[var(--color-ink)]"
            >
              {item.label}
            </a>
          ))}
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="py-2 text-[15px] text-[var(--color-ink-2)] hover:text-[var(--color-ink)]"
          >
            {t.github}
          </a>
        </div>
      )}
    </header>
  );
};
