import React from 'react';
import { 
  Sparkles, 
  Copy, 
  Terminal, 
  Code2, 
  FileCode2, 
  BookOpen,
  ShieldCheck, 
  Zap, 
  Cpu 
} from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface HeroProps {
  lang: Language;
}

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  const getPillarIcon = (id: string) => {
    switch (id) {
      case 'paths':
        return <Copy className="w-4 h-4 text-purple-400" />;
      case 'terminals':
        return <Terminal className="w-4 h-4 text-emerald-400" />;
      case 'editors':
        return <Code2 className="w-4 h-4 text-blue-400" />;
      case 'scripts':
        return <FileCode2 className="w-4 h-4 text-amber-400" />;
      default:
        return <Sparkles className="w-4 h-4 text-blue-400" />;
    }
  };

  return (
    <section className="relative pt-12 pb-16 md:pt-18 md:pb-20 overflow-hidden text-center px-4 sm:px-6">
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
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full glass-panel border border-white/10 text-xs text-zinc-300 mb-6 sm:mb-7 shadow-sm hover:border-white/20 transition-colors">
          <span className="flex h-2 w-2 relative">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
          </span>
          <span className="font-medium tracking-wide">{t.badge}</span>
        </div>

        {/* Hero Title */}
        <h1 className="text-4xl sm:text-6xl md:text-7xl font-bold tracking-tight text-white mb-5 leading-[1.12]">
          {t.titleStart}
          <span className="bg-gradient-to-r from-blue-400 via-sky-300 to-indigo-300 bg-clip-text text-transparent">
            {t.titleHighlight}
          </span>
        </h1>

        {/* Subtitle */}
        <p className="text-base sm:text-lg md:text-xl text-zinc-300 max-w-2xl mx-auto mb-8 font-normal leading-relaxed">
          {t.subtitle}
        </p>

        {/* Developer Focused CTA Buttons */}
        <div className="flex flex-col sm:flex-row items-center gap-3.5 w-full sm:w-auto mb-4">
          {/* Primary: GitHub */}
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3 rounded-xl text-sm font-semibold text-white bg-blue-600 hover:bg-blue-500 shadow-xl shadow-blue-600/30 hover:shadow-blue-500/40 transition-all duration-200 border border-blue-400/40 hover:-translate-y-0.5"
          >
            <GithubIcon className="w-4 h-4" />
            <span>{t.ctaPrimary}</span>
          </a>

          {/* Secondary: Quick Start Guide */}
          <a
            href="#guide"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-5 py-3 rounded-xl text-sm font-semibold text-zinc-200 glass-panel hover:bg-white/10 hover:text-white transition-all duration-200 border border-white/10 hover:-translate-y-0.5"
          >
            <BookOpen className="w-4 h-4 text-blue-400" />
            <span>{t.ctaSecondary}</span>
          </a>
        </div>

        {/* Release link */}
        <a
          href="https://github.com/tdawn0-0/FinderActions/releases"
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs text-zinc-400 hover:text-blue-400 transition-colors flex items-center gap-1 mb-10"
        >
          <span>{lang === 'zh' ? '获取最新 Release 发布版本 (.zip / .dmg) ›' : 'Get latest releases & changelog ›'}</span>
        </a>

        {/* 4 Core Pillars Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 w-full max-w-4xl text-left mb-8">
          {t.pillars.map((pillar) => (
            <div
              key={pillar.id}
              className="glass-panel rounded-xl p-3.5 border border-white/10 hover:border-white/20 transition-all bg-[#11131c]/60 flex flex-col justify-between"
            >
              <div className="flex items-center gap-2 mb-1.5">
                <div className="p-1 rounded-md bg-white/5 border border-white/10">
                  {getPillarIcon(pillar.id)}
                </div>
                <span className="text-xs font-semibold text-white tracking-tight">
                  {pillar.title}
                </span>
              </div>
              <p className="text-[11px] text-zinc-400 leading-relaxed">
                {pillar.desc}
              </p>
            </div>
          ))}
        </div>

        {/* Technical stats row */}
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
