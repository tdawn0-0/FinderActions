import React, { useState } from 'react';
import { Terminal, FileCode, Check, Copy, Code, FolderGit2 } from 'lucide-react';
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
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="scripting" className="py-16 md:py-24 px-4 sm:px-6 relative">
      <div className="max-w-5xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-xs text-purple-400 font-medium mb-3">
            <Code className="w-3.5 h-3.5" />
            <span>{t.tag}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white tracking-tight mb-3">
            {t.title}
          </h2>
          <p className="text-sm sm:text-base text-zinc-400 max-w-xl mx-auto">
            {t.description}
          </p>
        </div>

        {/* Code Editor Window */}
        <div className="rounded-2xl overflow-hidden glass-panel border border-white/10 shadow-2xl bg-[#0d0f17]/95">
          {/* Editor Header with Tabs and Traffic Lights */}
          <div className="h-11 px-4 border-b border-white/10 bg-[#141722]/80 flex items-center justify-between">
            <div className="flex items-center gap-3">
              {/* Traffic Lights */}
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-full bg-[#ff5f57]" />
                <div className="w-3 h-3 rounded-full bg-[#febc2e]" />
                <div className="w-3 h-3 rounded-full bg-[#28c840]" />
              </div>

              {/* Tabs */}
              <div className="flex items-center gap-1 ml-2 text-xs font-mono">
                <button
                  onClick={() => setActiveTab('script')}
                  className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-colors ${
                    activeTab === 'script'
                      ? 'bg-white/10 text-white font-semibold'
                      : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/5'
                  }`}
                >
                  <Terminal className="w-3.5 h-3.5 text-emerald-400" />
                  <span>{t.tabScript}</span>
                </button>

                <button
                  onClick={() => setActiveTab('manifest')}
                  className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-colors ${
                    activeTab === 'manifest'
                      ? 'bg-white/10 text-white font-semibold'
                      : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/5'
                  }`}
                >
                  <FileCode className="w-3.5 h-3.5 text-amber-400" />
                  <span>{t.tabManifest}</span>
                </button>

                <button
                  onClick={() => setActiveTab('output')}
                  className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-colors ${
                    activeTab === 'output'
                      ? 'bg-white/10 text-white font-semibold'
                      : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/5'
                  }`}
                >
                  <Code className="w-3.5 h-3.5 text-sky-400" />
                  <span>{t.tabOutput}</span>
                </button>
              </div>
            </div>

            {/* Copy Button */}
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium text-zinc-400 hover:text-white bg-white/5 hover:bg-white/10 transition-colors border border-white/5"
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

          {/* Code Body */}
          <div className="p-4 sm:p-6 overflow-x-auto text-xs sm:text-sm font-mono leading-relaxed bg-[#0b0c12]">
            <pre className="text-zinc-200">
              <code>{getActiveCode()}</code>
            </pre>
          </div>

          {/* Footer Callout */}
          <div className="px-4 py-3 border-t border-white/5 bg-[#12151e]/60 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 text-xs text-zinc-400">
            <div className="flex items-center gap-2">
              <FolderGit2 className="w-4 h-4 text-blue-400 shrink-0" />
              <span className="font-mono text-[11px] sm:text-xs text-zinc-300">
                {t.pathCallout}
              </span>
            </div>
            <div className="text-[11px] text-zinc-500">
              Zero sandbox friction • Native argv arrays
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
