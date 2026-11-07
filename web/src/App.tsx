import { useState, useEffect } from 'react';
import type { Language } from './types';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { FinderInteractiveMockup } from './components/FinderInteractiveMockup';
import { FeaturesBento } from './components/FeaturesBento';
import { ScriptShowcase } from './components/ScriptShowcase';
import { ArchitectureView } from './components/ArchitectureView';
import { GettingStarted } from './components/GettingStarted';
import { FaqSection } from './components/FaqSection';
import { Footer } from './components/Footer';

export function App() {
  const [lang, setLang] = useState<Language>(() => {
    if (typeof window !== 'undefined' && window.navigator) {
      const userLang = window.navigator.language || '';
      if (userLang.toLowerCase().includes('zh')) {
        return 'zh';
      }
    }
    return 'zh';
  });

  useEffect(() => {
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
  }, [lang]);

  const toggleLanguage = () => {
    setLang((prev) => (prev === 'en' ? 'zh' : 'en'));
  };

  return (
    <div className="min-h-screen bg-[#0b0c10] text-zinc-100 flex flex-col font-sans antialiased">
      <div
        className="fixed top-0 left-1/2 -translate-x-1/2 w-full max-w-5xl h-[360px] pointer-events-none opacity-20 overflow-hidden -z-10"
        aria-hidden="true"
      >
        <div className="absolute -top-24 left-1/2 -translate-x-1/2 w-[560px] h-[300px] rounded-full bg-sky-500/25 blur-[120px]" />
      </div>

      <Navbar lang={lang} onToggleLang={toggleLanguage} />

      <main className="flex-1 flex flex-col">
        <Hero lang={lang} />
        <FinderInteractiveMockup lang={lang} />
        <FeaturesBento lang={lang} />
        <ScriptShowcase lang={lang} />
        <ArchitectureView lang={lang} />
        <GettingStarted lang={lang} />
        <FaqSection lang={lang} />
      </main>

      <Footer lang={lang} />
    </div>
  );
}

export default App;
