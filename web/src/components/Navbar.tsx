import { latestReleaseURL } from '../release';
import React, { useState } from 'react';
import { Menu, X } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface NavbarProps {
  lang: Language;
  onToggleLang: () => void;
}

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
    <header className="sticky top-3 z-50 w-full px-4 sm:px-6">
      <div className="max-w-5xl mx-auto glass-panel rounded-xl px-4 py-2 flex items-center justify-between gap-4">
        <a href="#" className="flex items-center gap-2.5 shrink-0">
          <img
            src="/app-icon.png"
            alt=""
            className="w-7 h-7 rounded-md shrink-0"
          />
          <span className="font-semibold text-white tracking-tight text-sm whitespace-nowrap">
            FinderActions
          </span>
        </a>

        <nav className="hidden md:flex items-center gap-5 shrink-0">
          {navLinks.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="text-xs text-zinc-400 hover:text-white transition-colors whitespace-nowrap"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={onToggleLang}
            className="pressable px-2.5 py-1 rounded-md text-xs font-medium text-zinc-300 hover:text-white hover:bg-white/8 border border-white/8 cursor-pointer"
            aria-label="Switch language"
          >
            {lang === 'en' ? '中文' : 'EN'}
          </button>

          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            aria-label={t.github}
            className="pressable hidden sm:flex items-center justify-center p-1.5 rounded-md text-zinc-300 hover:text-white hover:bg-white/8 border border-white/8"
          >
            <GithubIcon className="w-4 h-4" />
          </a>

          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="pressable px-3 py-1 rounded-md text-xs font-medium text-white bg-[#0a84ff] hover:bg-[#1b8fff] whitespace-nowrap"
          >
            {t.download}
          </a>

          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-1.5 text-zinc-400 hover:text-white rounded-md hover:bg-white/8 cursor-pointer"
            aria-label="Toggle menu"
            aria-expanded={mobileMenuOpen}
          >
            {mobileMenuOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {mobileMenuOpen && (
        <div className="md:hidden mt-2 max-w-5xl mx-auto glass-dropdown rounded-xl p-3 flex flex-col gap-1">
          {navLinks.map((item) => (
            <a
              key={item.href}
              href={item.href}
              onClick={() => setMobileMenuOpen(false)}
              className="text-xs text-zinc-300 hover:text-white py-1.5 px-2.5 rounded-md hover:bg-white/6 transition-colors"
            >
              {item.label}
            </a>
          ))}
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-1 pt-2 border-t border-white/8 text-xs text-zinc-400 hover:text-white flex items-center gap-1.5 px-2.5 py-1"
          >
            <GithubIcon className="w-3.5 h-3.5" />
            <span>{t.github}</span>
          </a>
        </div>
      )}
    </header>
  );
};
