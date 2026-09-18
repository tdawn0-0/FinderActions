import React from 'react';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FooterProps {
  lang: Language;
}

export const Footer: React.FC<FooterProps> = ({ lang }) => {
  const t = translations[lang].footer;

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <footer className="border-t border-white/10 bg-[#07080c] py-12 px-4 sm:px-6 relative">
      <div className="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
        {/* Brand & Tagline */}
        <div className="flex flex-col items-center md:items-start gap-2">
          <div className="flex items-center gap-2.5">
            <img src="/app-icon.png" alt="FinderActions" className="w-6 h-6 rounded-md shadow" />
            <span className="font-semibold text-white tracking-tight text-sm">
              FinderActions
            </span>
            <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-white/10 text-zinc-400">
              MIT
            </span>
          </div>
          <p className="text-xs text-zinc-500 max-w-sm text-center md:text-left">
            {t.tagline}
          </p>
        </div>

        {/* Links */}
        <div className="flex items-center gap-6 text-xs text-zinc-400">
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-white transition-colors flex items-center gap-1.5"
          >
            <GithubIcon className="w-3.5 h-3.5" />
            <span>{t.github}</span>
          </a>
          <a
            href="https://github.com/tdawn0-0/FinderActions/releases"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-white transition-colors"
          >
            {t.releases}
          </a>
          <button
            onClick={scrollToTop}
            className="hover:text-white transition-colors flex items-center gap-1 text-zinc-400 cursor-pointer"
          >
            <span>{t.backToTop}</span>
          </button>
        </div>
      </div>

      <div className="max-w-5xl mx-auto mt-8 pt-6 border-t border-white/5 flex flex-col sm:flex-row items-center justify-between text-[11px] text-zinc-600 gap-2">
        <div>{t.builtWith}</div>
        <div>macOS is a trademark of Apple Inc.</div>
      </div>
    </footer>
  );
};
