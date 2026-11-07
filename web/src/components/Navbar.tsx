import { latestReleaseURL } from '../release';
import React, { useState } from 'react';
import { Menu, X } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface NavbarProps {
  lang: Language;
  onToggleLang: () => void;
}

export const BrandMark: React.FC = () => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 18 18"
    fill="none"
    aria-hidden="true"
    className="shrink-0 text-[#ededed]"
  >
    <path
      d="M2 4.5C2 3.67157 2.67157 3 3.5 3H6.67157C7.0694 3 7.45093 3.15804 7.73223 3.43934L8.56066 4.26777C8.84196 4.54907 9.2235 4.70711 9.62132 4.70711H14.5C15.3284 4.70711 16 5.37868 16 6.20711V13.5C16 14.3284 15.3284 15 14.5 15H3.5C2.67157 15 2 14.3284 2 13.5V4.5Z"
      stroke="currentColor"
      strokeWidth="1.5"
    />
    <path
      d="M7.25 8.5L5.75 10L7.25 11.5M10.75 8.5L12.25 10L10.75 11.5"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

export const Navbar: React.FC<NavbarProps> = ({ lang, onToggleLang }) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const t = translations[lang].nav;

  const navLinks = [
    { label: t.demo, href: '#demo' },
    { label: t.features, href: '#features' },
    { label: t.scripting, href: '#scripting' },
    { label: t.architecture, href: '#architecture' },
    { label: t.guide, href: '#guide' },
    { label: t.faq, href: '#faq' },
  ];

  return (
    <header className="sticky top-0 z-50 w-full bg-[#141415]/92 border-b border-[#ededed]/8">
      <div className="max-w-[1120px] mx-auto h-16 px-6 md:px-8 flex items-center justify-between gap-6">
        <div className="flex items-center gap-8">
          <a href="#" className="flex items-center gap-2.5 shrink-0">
            <BrandMark />
            <span className="text-[16px] leading-none font-medium text-[#ededed]">
              FinderActions
            </span>
          </a>

          <nav className="hidden md:flex items-center gap-6">
            {navLinks.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="text-[14px] leading-[20px] text-[#a1a1a6] hover:text-[#ededed] transition-colors"
              >
                {item.label}
              </a>
            ))}
          </nav>
        </div>

        <div className="flex items-center gap-4 shrink-0">
          <button
            type="button"
            onClick={onToggleLang}
            aria-label="Switch language"
            className="text-[13px] leading-[20px] text-[#a1a1a6] hover:text-[#ededed] transition-colors cursor-pointer"
          >
            {lang === 'en' ? '中文' : 'EN'}
          </button>

          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:inline-block text-[14px] leading-[20px] text-[#a1a1a6] hover:text-[#ededed] transition-colors"
          >
            {t.github}
          </a>

          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary h-9 px-4 rounded-[8px] inline-flex items-center justify-center text-[14px] leading-[20px] font-medium whitespace-nowrap"
          >
            {t.download}
          </a>

          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle menu"
            aria-expanded={mobileMenuOpen}
            className="md:hidden h-9 w-9 inline-flex items-center justify-center rounded-[8px] text-[#a1a1a6] hover:text-[#ededed] hover:bg-[#19191b] transition-colors cursor-pointer"
          >
            {mobileMenuOpen ? <X className="w-4 h-4" strokeWidth={1.5} /> : <Menu className="w-4 h-4" strokeWidth={1.5} />}
          </button>
        </div>
      </div>

      {mobileMenuOpen && (
        <div className="md:hidden border-t border-[#ededed]/8 bg-[#141415] px-6 py-4 flex flex-col gap-1">
          {navLinks.map((item) => (
            <a
              key={item.href}
              href={item.href}
              onClick={() => setMobileMenuOpen(false)}
              className="h-9 px-3 rounded-[8px] flex items-center text-[14px] text-[#a1a1a6] hover:text-[#ededed] hover:bg-[#19191b] transition-colors"
            >
              {item.label}
            </a>
          ))}
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="h-9 px-3 rounded-[8px] flex items-center text-[14px] text-[#a1a1a6] hover:text-[#ededed] hover:bg-[#19191b] transition-colors"
          >
            {t.github}
          </a>
        </div>
      )}
    </header>
  );
};
