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

  return (
    <section id="scripting" className="py-12 md:py-16 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-xl sm:text-2xl font-semibold text-white tracking-tight mb-5">
          {t.title}
        </h2>

        <div className="rounded-2xl overflow-hidden glass-panel border border-white/10 bg-[#0d0f15]">
          <div className="h-11 px-4 border-b border-white/8 bg-[#131620] flex items-center justify-between gap-2">
            <div className="flex items-center gap-1 text-xs font-mono overflow-x-auto">
              <button
                type="button"
                onClick={() => setActiveTab('script')}
                className={`pressable flex items-center gap-1.5 px-3 py-1 rounded-md cursor-pointer ${
                  activeTab === 'script'
                    ? 'bg-white/10 text-white font-medium'
                    : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/5'
                }`}
              >
                <Terminal className="w-3.5 h-3.5 text-emerald-400" />
                <span>{t.tabScript}</span>
              </button>

              <button
                type="button"
                onClick={() => setActiveTab('manifest')}
                className={`pressable flex items-center gap-1.5 px-3 py-1 rounded-md cursor-pointer ${
                  activeTab === 'manifest'
                    ? 'bg-white/10 text-white font-medium'
                    : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/5'
                }`}
              >
                <FileCode className="w-3.5 h-3.5 text-amber-400" />
                <span>{t.tabManifest}</span>
              </button>

              <button
                type="button"
                onClick={() => setActiveTab('output')}
                className={`pressable flex items-center gap-1.5 px-3 py-1 rounded-md cursor-pointer ${
                  activeTab === 'output'
                    ? 'bg-white/10 text-white font-medium'
                    : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/5'
                }`}
              >
                <Code className="w-3.5 h-3.5 text-sky-400" />
                <span>{t.tabOutput}</span>
              </button>
            </div>

            <button
              type="button"
              onClick={handleCopy}
              className="pressable flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium text-zinc-300 hover:text-white bg-white/5 hover:bg-white/10 border border-white/8 shrink-0 cursor-pointer"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400">{t.copied}</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>{t.copyCode}</span>
                </>
              )}
            </button>
          </div>

          <div className="p-4 sm:p-6 overflow-x-auto text-xs sm:text-[13px] font-mono leading-relaxed bg-[#0a0b10]">
            <pre className="text-zinc-200">
              <code>{getActiveCode()}</code>
            </pre>
          </div>

          <div className="px-4 py-2.5 border-t border-white/6 bg-[#11131b] flex items-center gap-2 text-xs text-zinc-400 font-mono">
            <Folder className="w-3.5 h-3.5 text-zinc-500 shrink-0" />
            <span className="truncate">{t.pathCallout}</span>
          </div>
        </div>
      </div>
    </section>
  );
};
