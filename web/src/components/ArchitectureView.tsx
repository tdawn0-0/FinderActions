import React from 'react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface ArchitectureViewProps {
  lang: Language;
}

export const ArchitectureView: React.FC<ArchitectureViewProps> = ({ lang }) => {
  const t = translations[lang].architecture;

  const processes = [
    { title: t.syncTitle, meta: t.syncMeta, desc: t.syncDesc },
    { title: t.hostTitle, meta: t.hostMeta, desc: t.hostDesc },
    { title: t.settingsTitle, meta: t.settingsMeta, desc: t.settingsDesc },
  ];

  return (
    <section id="architecture" className="py-12 md:py-16 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-xl sm:text-2xl font-semibold text-white tracking-tight mb-5">
          {t.title}
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          {processes.map((proc) => (
            <div
              key={proc.title}
              className="glass-panel rounded-2xl p-5 border border-white/8 bg-[#10121a]"
            >
              <div className="flex items-baseline justify-between gap-2 mb-2">
                <h3 className="text-sm font-semibold text-white tracking-tight">
                  {proc.title}
                </h3>
                <span className="text-[11px] font-mono text-zinc-400">
                  {proc.meta}
                </span>
              </div>
              <p className="text-xs text-zinc-400 leading-relaxed">
                {proc.desc}
              </p>
            </div>
          ))}
        </div>

        <div className="glass-panel rounded-2xl overflow-hidden border border-white/8 bg-[#0e1017]">
          <div className="grid grid-cols-3 px-5 py-2.5 border-b border-white/8 bg-[#131620] text-[11px] font-medium text-zinc-400">
            <span>{t.compHeaders[0]}</span>
            <span>{t.compHeaders[1]}</span>
            <span>{t.compHeaders[2]}</span>
          </div>
          <div className="divide-y divide-white/5 text-xs">
            {t.compRows.map((row) => (
              <div key={row.label} className="grid grid-cols-3 px-5 py-3 items-center">
                <span className="text-zinc-300">{row.label}</span>
                <span className="text-white font-mono">{row.fa}</span>
                <span className="text-zinc-500 font-mono">{row.others}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};
