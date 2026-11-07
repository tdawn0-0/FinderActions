import React from 'react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FeaturesBentoProps {
  lang: Language;
}

export const FeaturesBento: React.FC<FeaturesBentoProps> = ({ lang }) => {
  const t = translations[lang].features;

  return (
    <section id="features" className="py-20 md:py-24 px-6 md:px-8 border-t border-[#ededed]/8">
      <div className="max-w-[1120px] mx-auto">
        <h2 className="text-[28px] md:text-[32px] leading-[1.15] font-medium text-[#ededed] mb-10">
          {t.title}
        </h2>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
          <div className="lg:col-span-7 rounded-[16px] bg-[#19191b] border border-[#ededed]/8 p-6 flex flex-col justify-between gap-6">
            <div>
              <h3 className="text-[16px] leading-[22px] font-medium text-[#ededed] mb-2">
                {t.scriptsTitle}
              </h3>
              <p className="text-[14px] leading-[22px] text-[#a1a1a6] max-w-[54ch]">
                {t.scriptsDesc}
              </p>
            </div>

            <div className="rounded-[8px] bg-[#0f0f10] border border-[#ededed]/8 p-4 font-mono text-[12px] leading-[20px] text-[#a1a1a6] flex flex-col gap-1.5">
              <div className="flex items-center justify-between text-[#85858b]">
                <span>argv</span>
                <kbd className="keycap">.faaction</kbd>
              </div>
              <div className="text-[#ededed] truncate">
                [0] /bin/zsh &nbsp;[1] compress.zsh &nbsp;[2] "/Users/dev/ My File.png"
              </div>
            </div>
          </div>

          <div className="lg:col-span-5 rounded-[16px] bg-[#19191b] border border-[#ededed]/8 p-6 flex flex-col justify-between gap-6">
            <div>
              <h3 className="text-[16px] leading-[22px] font-medium text-[#ededed] mb-2">
                {t.pathsTitle}
              </h3>
              <p className="text-[14px] leading-[22px] text-[#a1a1a6]">
                {t.pathsDesc}
              </p>
            </div>

            <div className="rounded-[8px] bg-[#0f0f10] border border-[#ededed]/8 px-3 h-10 flex items-center justify-between font-mono text-[12px] text-[#ededed]">
              <span className="truncate">/Users/dev/Project-Assets/hero-banner.png</span>
              <span className="text-[#4cc38a] shrink-0 ml-3">pbcopy</span>
            </div>
          </div>

          <div className="lg:col-span-6 rounded-[16px] bg-[#19191b] border border-[#ededed]/8 p-6 flex flex-col justify-between gap-5">
            <div>
              <h3 className="text-[16px] leading-[22px] font-medium text-[#ededed] mb-1.5">
                {t.terminalsTitle}
              </h3>
              <p className="text-[14px] leading-[22px] text-[#a1a1a6]">
                {t.terminalsDesc}
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              {t.terminalsList.map((name) => (
                <kbd key={name} className="keycap">
                  {name}
                </kbd>
              ))}
            </div>
          </div>

          <div className="lg:col-span-6 rounded-[16px] bg-[#19191b] border border-[#ededed]/8 p-6 flex flex-col justify-between gap-5">
            <div>
              <h3 className="text-[16px] leading-[22px] font-medium text-[#ededed] mb-1.5">
                {t.editorsTitle}
              </h3>
              <p className="text-[14px] leading-[22px] text-[#a1a1a6]">
                {t.editorsDesc}
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              {t.editorsList.map((name) => (
                <kbd key={name} className="keycap">
                  {name}
                </kbd>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
