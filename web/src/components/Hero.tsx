import React from 'react';
import { Download, Sparkles, ShieldCheck, Zap, Cpu } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface HeroProps {
  lang: Language;
}

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  return (
    <section className="relative pt-12 pb-16 md:pt-20 md:pb-24 overflow-hidden text-center px-4 sm:px-6">
      {/* Background Ambient Glows */}
      <div 
        className="ambient-glow bg-blue-600/20 w-[500px] h-[300px] -top-20 left-1/2 -translate-x-1/2" 
        aria-hidden="true"
      />
      <div 
        className="ambient-glow bg-purple-600/15 w-[350px] h-[250px] top-40 left-1/3 -translate-x-1/2" 
        aria-hidden="true"
      />

      <div className="relative max-w-4xl mx-auto flex flex-col items-center">
        {/* Pill Badge */}
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full glass-panel border border-white/10 text-xs text-zinc-300 mb-6 sm:mb-8 shadow-sm hover:border-white/20 transition-colors">
          <span className="flex h-2 w-2 relative">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
          </span>
          <span className="font-medium tracking-wide">{t.badge}</span>
        </div>

        {/* Hero Title */}
        <h1 className="text-4xl sm:text-6xl md:text-7xl font-bold tracking-tight text-white mb-6 leading-[1.1]">
          {t.titleStart}
          <span className="bg-gradient-to-r from-blue-400 via-sky-300 to-indigo-300 bg-clip-text text-transparent">
            {t.titleHighlight}
          </span>
        </h1>

        {/* Subtitle */}
        <p className="text-base sm:text-lg md:text-xl text-zinc-300 max-w-2xl mx-auto mb-8 font-normal leading-relaxed">
          {t.subtitle}
        </p>

        {/* Primary Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center gap-3.5 w-full sm:w-auto mb-8">
          <a
            href="https://github.com/tdawn0-0/FinderActions/releases"
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3 rounded-xl text-sm font-semibold text-white bg-blue-600 hover:bg-blue-500 shadow-xl shadow-blue-600/30 hover:shadow-blue-500/40 transition-all duration-200 border border-blue-400/40 hover:-translate-y-0.5"
          >
            <Download className="w-4 h-4" />
            <span>{t.ctaPrimary}</span>
          </a>

          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-5 py-3 rounded-xl text-sm font-semibold text-zinc-200 glass-panel hover:bg-white/10 hover:text-white transition-all duration-200 border border-white/10 hover:-translate-y-0.5"
          >
            <GithubIcon className="w-4 h-4" />
            <span>{t.ctaSecondary}</span>
          </a>
        </div>

        {/* Micro highlights pill bar */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 max-w-2xl w-full pt-4 border-t border-white/5 text-xs text-zinc-400 font-medium">
          <div className="flex items-center justify-center gap-1.5 py-1">
            <Cpu className="w-3.5 h-3.5 text-blue-400" />
            <span>&lt; 10MB RAM</span>
          </div>
          <div className="flex items-center justify-center gap-1.5 py-1">
            <Zap className="w-3.5 h-3.5 text-amber-400" />
            <span>0% Idle CPU</span>
          </div>
          <div className="flex items-center justify-center gap-1.5 py-1">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
            <span>100% Private</span>
          </div>
          <div className="flex items-center justify-center gap-1.5 py-1">
            <Sparkles className="w-3.5 h-3.5 text-purple-400" />
            <span>SwiftUI Native</span>
          </div>
        </div>
      </div>
    </section>
  );
};
