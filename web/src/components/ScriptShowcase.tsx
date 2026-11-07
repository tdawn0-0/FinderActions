import React, { useState } from 'react';
import { Terminal, FileCode, Check, Copy, Code, Folder } from 'lucide-react';
import type { Language } from '../types';
import { translations, codeSnippets } from '../i18n';

interface ScriptShowcaseProps {
  lang: Language;
}

export const ScriptShowcase: React.FC<ScriptShowcaseProps> = ({ lang }) => {
  const t = translations[lang].scripting;
  const [activeTab, setActiveTab] = useState<'script' | 'manifest' | 'output'>('script');
  const [copied, setCopied] = useState(false);

  const getActiveCode = () => {
    switch (activeTab) {
      case 'script':
        return codeSnippets.script;
      case 'manifest':
        return codeSnippets.manifest;
      case 'output':
        return codeSnippets.output;
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(getActiveCode());
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  const tabs = [
    { id: 'script' as const, label: t.tabScript, icon: Terminal },
    { id: 'manifest' as const, label: t.tabManifest, icon: FileCode },
    { id: 'output' as const, label: t.tabOutput, icon: Code },
  ];

  return (
    <section id="scripting" className="py-20 md:py-24 px-6 md:px-8 border-t border-[#ededed]/8">
      <div className="max-w-[1120px] mx-auto grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
        <div className="lg:col-span-4 flex flex-col gap-6">
          <div>
            <h2 className="text-[28px] md:text-[32px] leading-[1.15] font-medium text-[#ededed] mb-3">
              {t.title}
            </h2>
            <p className="text-[14px] leading-[22px] text-[#a1a1a6]">
              {t.desc}
            </p>
          </div>

          <div className="border-t border-[#ededed]/8 pt-5">
            <div className="text-[12px] leading-[16px] text-[#85858b] mb-3">
              {t.envTitle}
            </div>
            <div className="flex flex-col gap-2.5">
              {t.envVars.map((item) => (
                <div key={item.key} className="flex items-center justify-between gap-3 text-[13px] leading-[20px]">
                  <kbd className="keycap">{item.key}</kbd>
                  <span className="text-[#a1a1a6] text-right">{item.note}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="lg:col-span-8 rounded-[16px] overflow-hidden bg-[#19191b] border border-[#ededed]/8">
          <div className="h-12 px-2 border-b border-[#ededed]/8 flex items-center justify-between gap-2">
            <div className="flex items-center gap-1 overflow-x-auto">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                const active = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    type="button"
                    onClick={() => setActiveTab(tab.id)}
                    className={`h-8 px-3 rounded-[8px] flex items-center gap-2 text-[12px] leading-[16px] font-mono transition-colors cursor-pointer ${
                      active
                        ? 'surface-active text-[#ededed]'
                        : 'text-[#85858b] hover:text-[#ededed]'
                    }`}
                  >
                    <Icon className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </div>

            <button
              type="button"
              onClick={handleCopy}
              className="btn-secondary h-8 px-3 rounded-[8px] inline-flex items-center gap-2 text-[12px] leading-[16px] shrink-0 cursor-pointer"
            >
              {copied ? (
                <>
                  <Check className="w-4 h-4 text-[#4cc38a] shrink-0" strokeWidth={1.5} />
                  <span className="text-[#4cc38a]">{t.copied}</span>
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
                  <span>{t.copyCode}</span>
                </>
              )}
            </button>
          </div>

          <div className="p-6 overflow-x-auto text-[13px] leading-[22px] font-mono bg-[#0f0f10]">
            <pre className="text-[#ededed]">
              <code>{getActiveCode()}</code>
            </pre>
          </div>

          <div className="h-10 px-4 border-t border-[#ededed]/8 bg-[#19191b] flex items-center gap-2 text-[12px] leading-[16px] text-[#85858b] font-mono">
            <Folder className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
            <span className="truncate">{t.pathCallout}</span>
          </div>
        </div>
      </div>
    </section>
  );
};
