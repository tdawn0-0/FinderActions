import React from 'react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface ArchitectureViewProps {
  lang: Language;
}

export const ArchitectureView: React.FC<ArchitectureViewProps> = ({ lang }) => {
  const t = translations[lang].architecture;

  return (
    <section id="architecture" className="py-20 md:py-24 px-6 md:px-8 border-t border-[#ededed]/8">
      <div className="max-w-[1120px] mx-auto">
        <h2 className="text-[28px] md:text-[32px] leading-[1.15] font-medium text-[#ededed] mb-10">
          {t.title}
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
          {t.stats.map((stat, idx) => (
            <div
              key={stat.label}
              className="rounded-[16px] bg-[#19191b] border border-[#ededed]/8 p-6 flex flex-col gap-2"
            >
              <span className="text-[13px] leading-[20px] text-[#a1a1a6]">
                {stat.label}
              </span>
              <span
                className={`text-[32px] leading-none font-medium font-mono tabular-nums ${
                  idx === 0 ? 'text-[#0a84ff]' : 'text-[#ededed]'
                }`}
              >
                {stat.value}
              </span>
              <span className="text-[12px] leading-[16px] text-[#85858b]">
                {stat.note}
              </span>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
          <div className="lg:col-span-5 rounded-[16px] bg-[#19191b] border border-[#ededed]/8 divide-y divide-[#ededed]/8">
            {t.processes.map((proc) => (
              <div key={proc.name} className="p-5 flex flex-col gap-1.5">
                <div className="flex items-baseline justify-between gap-2">
                  <h3 className="text-[15px] leading-[22px] font-medium text-[#ededed]">
                    {proc.name}
                  </h3>
                  <span className="text-[12px] leading-[16px] font-mono text-[#85858b]">
                    {proc.role}
                  </span>
                </div>
                <p className="text-[13px] leading-[20px] text-[#a1a1a6]">
                  {proc.desc}
                </p>
              </div>
            ))}
          </div>

          <div className="lg:col-span-7 rounded-[16px] overflow-hidden bg-[#19191b] border border-[#ededed]/8 flex flex-col justify-between">
            <div className="grid grid-cols-3 h-11 px-5 border-b border-[#ededed]/8 items-center text-[12px] leading-[16px] text-[#85858b]">
              <span>{t.compHeaders[0]}</span>
              <span>{t.compHeaders[1]}</span>
              <span>{t.compHeaders[2]}</span>
            </div>
            <div className="divide-y divide-[#ededed]/8 flex-1 flex flex-col justify-around">
              {t.compRows.map((row) => (
                <div key={row.label} className="grid grid-cols-3 px-5 py-4 items-center text-[13px] leading-[20px] gap-3">
                  <span className="text-[#a1a1a6]">{row.label}</span>
                  <span className="text-[#ededed] font-mono text-[12px]">{row.fa}</span>
                  <span className="text-[#85858b] font-mono text-[12px]">{row.others}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
