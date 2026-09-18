import React, { useState } from 'react';
import { Globe, Download, Menu, X } from 'lucide-react';
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
    { label: t.features, href: "#features" },
    { label: t.demo, href: "#demo" },
    { label: t.scripting, href: "#scripting" },
    { label: t.architecture, href: "#architecture" },
    { label: t.guide, href: "#guide" },
    { label: t.faq, href: "#faq" },
  ];

  return (
    <header className="sticky top-4 z-50 w-full px-3 sm:px-6">
      <div className="max-w-5xl lg:max-w-6xl mx-auto glass-panel rounded-2xl px-3.5 sm:px-5 py-2 sm:py-2.5 flex items-center justify-between gap-2 sm:gap-4 border border-white/10 shadow-2xl backdrop-blur-2xl bg-[#12151e]/85">
        {/* Brand */}
        <a href="#" className="flex items-center gap-2 sm:gap-2.5 group shrink-0">
          <img 
            src="/app-icon.png" 
            alt="FinderActions Icon" 
            className="w-7 h-7 sm:w-8 sm:h-8 rounded-lg shadow-md transition-transform duration-300 group-hover:scale-105 shrink-0"
          />
          <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
            <span className="font-semibold text-white tracking-tight text-xs sm:text-sm lg:text-base whitespace-nowrap">
              FinderActions
            </span>
            <span className="hidden sm:inline-block text-[10px] font-mono px-1.5 py-0.5 rounded bg-white/10 text-zinc-300 border border-white/10 whitespace-nowrap shrink-0">
              macOS 15+
            </span>
          </div>
        </a>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-3.5 lg:gap-6 shrink-0">
          {navLinks.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="text-xs lg:text-sm text-zinc-400 hover:text-white transition-colors font-normal tracking-wide whitespace-nowrap shrink-0"
            >
              {item.label}
            </a>
          ))}
        </nav>

        {/* Actions */}
        <div className="flex items-center gap-1.5 sm:gap-2.5 shrink-0">
          {/* Language Toggle */}
          <button
            onClick={onToggleLang}
            className="flex items-center gap-1 sm:gap-1.5 px-2 sm:px-2.5 py-1.5 rounded-lg text-xs font-medium text-zinc-300 hover:text-white hover:bg-white/10 transition-colors border border-white/5 whitespace-nowrap shrink-0 cursor-pointer"
            title="Switch Language"
          >
            <Globe className="w-3.5 h-3.5 text-blue-400 shrink-0" />
            <span className="whitespace-nowrap">{lang === 'en' ? '中文' : 'EN'}</span>
          </button>

          {/* GitHub Repo */}
          <a
            href="https://github.com/jyeu/finder-menu"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium text-zinc-300 hover:text-white hover:bg-white/10 transition-colors border border-white/5 whitespace-nowrap shrink-0"
          >
            <GithubIcon className="w-3.5 h-3.5 shrink-0" />
            <span className="whitespace-nowrap">{t.github}</span>
          </a>

          {/* Download CTA */}
          <a
            href="#guide"
            className="flex items-center gap-1.5 px-3 sm:px-3.5 py-1.5 rounded-lg text-xs font-semibold text-white bg-gradient-to-b from-blue-500 to-blue-600 hover:from-blue-400 hover:to-blue-500 shadow-md shadow-blue-500/25 transition-all duration-200 border border-blue-400/30 whitespace-nowrap shrink-0"
          >
            <Download className="w-3.5 h-3.5 shrink-0" />
            <span className="whitespace-nowrap">{t.download}</span>
          </a>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-1.5 text-zinc-400 hover:text-white rounded-lg hover:bg-white/10 transition-colors shrink-0"
            aria-label="Toggle menu"
          >
            {mobileMenuOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden mt-2 max-w-5xl mx-auto glass-dropdown rounded-xl p-4 flex flex-col gap-3 border border-white/10 animate-in fade-in slide-in-from-top-2 duration-200">
          {navLinks.map((item) => (
            <a
              key={item.href}
              href={item.href}
              onClick={() => setMobileMenuOpen(false)}
              className="text-sm text-zinc-300 hover:text-white py-1 px-2 rounded hover:bg-white/5 transition-colors"
            >
              {item.label}
            </a>
          ))}
          <div className="pt-2 border-t border-white/10 flex items-center justify-between">
            <a
              href="https://github.com/jyeu/finder-menu"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-zinc-400 hover:text-white flex items-center gap-1.5 py-1"
            >
              <GithubIcon className="w-4 h-4" />
              <span>{t.github}</span>
            </a>
            <span className="text-[11px] text-zinc-500 font-mono">Swift 6 & AppKit</span>
          </div>
        </div>
      )}
    </header>
  );
};
