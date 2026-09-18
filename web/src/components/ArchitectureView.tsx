import React from 'react';
import { Layers, Cpu, CheckCircle, Zap, Activity } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface ArchitectureViewProps {
  lang: Language;
}

export const ArchitectureView: React.FC<ArchitectureViewProps> = ({ lang }) => {
  const t = translations[lang].architecture;

  return (
    <section id="architecture" className="py-16 md:py-24 px-4 sm:px-6 relative">
      <div className="max-w-5xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-xs text-indigo-400 font-medium mb-3">
            <Layers className="w-3.5 h-3.5" />
            <span>{t.tag}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white tracking-tight mb-3">
            {t.title}
          </h2>
          <p className="text-sm sm:text-base text-zinc-400 max-w-2xl mx-auto">
            {t.subtitle}
          </p>
        </div>

        {/* 3 Pillars Flow Diagram */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-12">
          {/* Pillar 1: Settings Helper */}
          <div className="glass-panel rounded-2xl p-6 border border-white/10 bg-[#121520]/80 flex flex-col justify-between relative group hover:border-purple-500/30 transition-all">
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-purple-500/20 text-purple-300 border border-purple-500/30">
                  Ephemeral UI
                </span>
                <Activity className="w-4 h-4 text-purple-400" />
              </div>
              <h3 className="text-base font-semibold text-white tracking-tight mb-2">
                {t.settingsTitle}
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed font-normal">
                {t.settingsDesc}
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-white/5 text-[11px] font-mono text-purple-400/80">
              SwiftUI 6 • Exits on close
            </div>
          </div>

          {/* Pillar 2: Host (Center Stage) */}
          <div className="glass-panel rounded-2xl p-6 border border-blue-500/40 bg-[#141828]/90 flex flex-col justify-between relative shadow-xl shadow-blue-500/5 group">
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-blue-600 text-white text-[10px] font-semibold px-2.5 py-0.5 rounded-full shadow-md">
              Core Engine
            </div>
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-500/20 text-blue-300 border border-blue-500/30">
                  Resident &lt;10MB
                </span>
                <Cpu className="w-4 h-4 text-blue-400" />
              </div>
              <h3 className="text-base font-semibold text-white tracking-tight mb-2">
                {t.hostTitle}
              </h3>
              <p className="text-xs text-zinc-300 leading-relaxed font-normal">
                {t.hostDesc}
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-white/10 text-[11px] font-mono text-blue-400">
              Pure AppKit • Non-Sandboxed
            </div>
          </div>

          {/* Pillar 3: FinderSync */}
          <div className="glass-panel rounded-2xl p-6 border border-white/10 bg-[#121520]/80 flex flex-col justify-between relative group hover:border-emerald-500/30 transition-all">
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                  Ultra Thin
                </span>
                <Zap className="w-4 h-4 text-emerald-400" />
              </div>
              <h3 className="text-base font-semibold text-white tracking-tight mb-2">
                {t.syncTitle}
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed font-normal">
                {t.syncDesc}
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-white/5 text-[11px] font-mono text-emerald-400/80">
              Sandboxed UI Probe • Zero Scripts
            </div>
          </div>
        </div>

        {/* Comparison Table */}
        <div className="glass-panel rounded-2xl overflow-hidden border border-white/10 bg-[#0d0f17]/90">
          <div className="px-6 py-4 border-b border-white/10 bg-[#141722]/80 flex items-center justify-between">
            <h3 className="text-sm font-semibold text-white tracking-tight">
              {t.comparisonTitle}
            </h3>
            <span className="text-[11px] font-mono text-zinc-400">Benchmarked on macOS 15</span>
          </div>

          <div className="divide-y divide-white/5 text-xs sm:text-sm">
            {t.compRows.map((row, idx) => (
              <div key={idx} className="grid grid-cols-3 px-6 py-3.5 items-center hover:bg-white/5 transition-colors">
                <span className="font-medium text-zinc-300">{row.label}</span>
                <span className="text-emerald-400 font-mono font-semibold flex items-center gap-1.5">
                  <CheckCircle className="w-3.5 h-3.5 shrink-0" />
                  {row.fa}
                </span>
                <span className="text-zinc-500 font-mono text-xs">{row.others}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};
